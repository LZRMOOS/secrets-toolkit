# script to use GitHub's octokit api to get the security secret scanning results for all repos in an organization
require 'csv'
require 'octokit'
require 'json'

ORG_NAME = '<ORG>'
ACCESS_TOKEN = '<PAT>'
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
    alert_data = {
      researcher: '',
      ruleid: alert['secret_type_display_name'],
      analysis: '',
      priority: '',
      in_code: '',
      file: alert['locations_url'],
      repository: alert['repository']['full_name'],
      initial_migration: '',
      revoked: '',
      action: '',
      secret: alert['secret'],
      match: '',
      commit: '',
      startline: '',
      endline: '',
      startcol: '',
      endcol: '',
      author: '',
      date: '',
      email: '',
      fingerprint: '',
      url: alert['html_url'],
      notes: ''
    }

    alerts_data << alert_data
    puts alerts_data.count
  end
  page += 1
end

# Export data to CSV file
require 'csv'

csv_file = "#{CSV_FILENAME}"

CSV.open(csv_file, 'w') do |csv|
  # csv << ['Researcher', 'RuleID', 'Analysis', 'Priority', 'State', 'Created At', 'URL']

  alerts_data.each do |alert_data|
    csv << alert_data.values
  end
end

puts "Secret scanning alerts exported to #{csv_file}"
