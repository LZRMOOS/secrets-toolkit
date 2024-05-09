require 'csv'
require 'date'
require 'json'

ACCESS_TOKEN = ENV['GH_PAT']
USERNAME = "@weid"
DATE = Date.today.to_s

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

      locations_json.each do |location|
        location_details = location['details']
        note = ''
        gh_url = "https://github.com/" +
            "#{org_name}/" +
            "#{alert['repository']['name']}/blob/" +
            "#{location_details['commit_sha']}/" +
            "#{location_details['path']}#L" +
            "#{location_details['start_line']}"

        if location_details['commit_sha'].nil?
          note = "You'll need to refer to the Alert URL: #{alert['html_url']}. The GitHub API is broken, #{locations_url} is giving incomplete data" 
        else 
          commit_url = location_details['commit_url']
          commit = `#{curl_cmd("#{commit_url}")}`
          commit_info = JSON.parse(commit)
          committer_name = commit_info['committer']['name']
          committer_email = commit_info['committer']['email']
          committer_date = commit_info['committer']['date']
        end
       
        alert_data = {
          number: alert['number'],
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
          gh_url: gh_url,
          resolution_comment: alert['resolution_comment'],
          committer_name: committer_name,
          committer_email: committer_email,
          committer_date: committer_date,
          note: note
        }
  
        alerts_data << alert_data
      end
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
  csv_file = "#{org_name}-#{DATE}-ghasss-results-by-#{USERNAME}.csv"

  CSV.open(csv_file, 'w') do |csv|
    csv << ['Alert Number', 'RuleID', 'File', 'Org/Repo', 'Secret', 'Validity', 'State', 'Resolution', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL', 'Resolution Comment', 'Committer Name', 'Committer Email', 'Committer Date', 'Note']
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
