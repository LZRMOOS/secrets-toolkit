require 'csv'
require 'json'

ORG_NAME = '<ORG>'
ACCESS_TOKEN = ENV['GH_PAT']
CSV_FILENAME = "wei-ghas-secrets-results-#{ORG_NAME}.csv"

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
  secret_alerts = `#{curl_cmd("https://api.github.com/orgs/#{ORG_NAME}/secret-scanning/alerts?page=#{page}")}`
  secret_alerts_json = JSON.parse(secret_alerts)

  break if secret_alerts_json.empty?

  secret_alerts_json.each do |alert|
    locations_url = alert['locations_url']
    break if locations_url.empty?
    
    locations = `#{curl_cmd("#{locations_url}")}`
    locations_json = JSON.parse(locations)

    location_details = locations_json.first['details']
    gh_url = "https://github.com/" +
          "#{ORG_NAME}/" +
          "#{alert['repository']['name']}/blob/" +
          "#{location_details['commit_sha']}/" +
          "#{location_details['path']}#L" +
          "#{location_details['start_line']}"

    alert_data = {
      ruleid: alert['secret_type_display_name'],
      file: location_details['path'],
      repository: alert['repository']['full_name'],
      secret: alert['secret'],
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

puts "Found #{alerts_data.count} secret scanning alerts"

csv_file = "#{CSV_FILENAME}"

CSV.open(csv_file, 'w') do |csv|
  csv << ['RuleID', 'File', 'Org/Repo', 'Secret', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL']
  alerts_data.each do |alert_data|
    csv << alert_data.values
  end
end

puts "Secret scanning alerts exported to #{csv_file}"
