require 'csv'
require 'json'

ACCESS_TOKEN = ENV['GH_PAT']
CSV_FILE_PREFIX = "weid"

def get_alerts_for_organization(org_name)
  alerts_data = []
  page = 1

  def curl_cmd(url)
    "curl -L \
    -H 'Accept: application/vnd.github+json' \
    -H 'Authorization: Bearer #{ACCESS_TOKEN}' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    #{url}"
  end

  loop do
    secret_alerts = `#{curl_cmd("https://api.github.com/orgs/#{org_name}/secret-scanning/alerts?page=#{page}")}`
    secret_alerts_json = JSON.parse(secret_alerts)

    break if secret_alerts_json.empty?

    secret_alerts_json.each do |alert|
      locations_url = alert['locations_url']
      break if locations_url.empty?

      locations = `#{curl_cmd("#{locations_url}")}`
      locations_json = JSON.parse(locations)

      location_details = locations_json.first['details']
      gh_url = "https://github.com/" +
            "#{org_name}/" +
            "#{alert['repository']['name']}/blob/" +
            "#{location_details['commit_sha']}/" +
            "#{location_details['path']}#L" +
            "#{location_details['start_line']}"

      alert_data = {
        ruleid: alert['secret_type_display_name'],
        file: location_details['path'],
        repository: alert['repository']['full_name'],
        secret: alert['secret'],
        validity: alert['validity'],
        state: alert['state'],
        resolution: alert['resolution'],
        commit: location_details['commit_sha'],
        startline: location_details['start_line'],
        endline:  location_details['end_line'],
        url: alert['html_url'],
        gh_url: gh_url
      }

      alerts_data << alert_data
    end
    page += 1
  end

  alerts_data
end

def process_organizations_from_file(file_path)
  organizations = File.readlines(file_path, chomp: true)
  organizations.each do |org_name|
    alerts_data = get_alerts_for_organization(org_name)
    export_to_csv(alerts_data, org_name)
  end
end

def export_to_csv(alerts_data, org_name)
  csv_file = "#{CSV_FILE_PREFIX}-ghasss-results-for-#{org_name}.csv"

  CSV.open(csv_file, 'w') do |csv|
    csv << ['RuleID', 'File', 'Org/Repo', 'Secret', 'Validity', 'State', 'Resolution', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL']
    alerts_data.each do |alert_data|
      csv << alert_data.values
    end
  end

  puts "Secret scanning alerts for #{org_name} exported to #{csv_file}"
end

if ARGV.empty?
  puts "Please provide either an organization name or a file containing organization names."
else
  input = ARGV[0]

  if File.file?(input)
    process_organizations_from_file(input)
  else
    alerts_data = get_alerts_for_organization(input)
    export_to_csv(alerts_data, input)
  end
end
