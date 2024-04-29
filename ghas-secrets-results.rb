require 'csv'
require 'json'

ORG_NAME = '<ORG>'
ACCESS_TOKEN = ENV['GH_PAT']
CSV_FILENAME = "wei-ghas-secrets-results-#{ORG_NAME}.csv"

alerts_data = []
page = 1

loop do
  curl_command = "curl -L \
  -H 'Accept: application/vnd.github+json' \
  -H 'Authorization: Bearer #{ACCESS_TOKEN}' \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  https://api.github.com/orgs/#{ORG_NAME}/secret-scanning/alerts?page=#{page}"

  # Execute curl command and capture output
  curl_output = `#{curl_command}`
  # Parse JSON response
  response = JSON.parse(curl_output)

  break if response.empty?

  # Process JSON response
  response.each do |alert|
    locations_url = alert['locations_url']
    break if locations_url.empty?
    locations_curl_cmd = "curl -L \
    -H 'Accept: application/vnd.github+json' \
    -H 'Authorization: Bearer #{ACCESS_TOKEN}' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    #{locations_url}"
    loc_curl_output = `#{locations_curl_cmd}`
    loc_response = JSON.parse(loc_curl_output)
    l_response = loc_response.first['details']

    ghurl_url = "https://github.com/#{ORG_NAME}/#{alert['repository']['name']}/blob/#{l_response['commit_sha']}/#{l_response['path']}#L#{l_response['start_line']}"

    alert_data = {
      ruleid: alert['secret_type_display_name'],
      file: l_response['path'],
      repository: alert['repository']['full_name'],
      secret: alert['secret'],
      commit: l_response['commit_sha'],
      startline: l_response['start_line'],
      endline:  l_response['end_line'],
      url: alert['html_url'],
      gh_url: ghurl_url
    }

    alerts_data << alert_data
  end
  page += 1
end

puts alerts_data.count

csv_file = "#{CSV_FILENAME}"

CSV.open(csv_file, 'w') do |csv|
  csv << ['RuleID', 'File', 'Org/Repo', 'Secret', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL']

  alerts_data.each do |alert_data|
    csv << alert_data.values
  end
end

puts "Secret scanning alerts exported to #{csv_file}"
