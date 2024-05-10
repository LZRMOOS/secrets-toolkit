require 'csv'
require 'date'
require 'json'
require 'open-uri'

ACCESS_TOKEN = ENV['GH_PAT']
USERNAME = "@weid"
DATE = Date.today.to_s

def fetch_data(url)
  URI.open(url, 'Accept' => 'application/vnd.github+json',
                'Authorization' => "Bearer #{ACCESS_TOKEN}",
                'X-GitHub-Api-Version' => '2022-11-28').read
end

def get_alerts_for_organization(org_name)
  puts "Organization: #{org_name} - #{Time.now}\n------------------------------------------------------------------\n"
  alerts_data = []
  page = 1

  loop do
    secret_alerts = fetch_data("https://api.github.com/orgs/#{org_name}/secret-scanning/alerts?page=#{page}")
    secret_alerts_json = JSON.parse(secret_alerts)

    break if secret_alerts_json.empty?

    secret_alerts_json.each do |alert|
      locations_url = alert['locations_url']
      next if locations_url.empty?

      locations_json = JSON.parse(fetch_data(locations_url))

      locations_json.each do |location|
        location_details = location['details']
        note, committer_name, committer_date, committer_email, gh_url, file_path = ''
        if !location_details['issue_comment_url'].nil?
          issue_comment_info = JSON.parse(fetch_data(location_details['issue_comment_url']))
          file_path = 'Refer to GitHub URL'
          committer_name = issue_comment_info['user']['login']
          committer_email = issue_comment_info['user']['html_url']
          committer_date = issue_comment_info['created_at']
          gh_url = issue_comment_info['html_url']
          note = 'Secret found in issue comment, refer to the GitHub URL column'
        elsif !location_details['commit_sha'].nil?
          commit_info = JSON.parse(fetch_data(location_details['commit_url']))
          file_path = location_details['path']
          committer_name = commit_info['committer']['name']
          committer_email = commit_info['committer']['email']
          committer_date = commit_info['committer']['date']
          gh_url = "https://github.com/#{org_name}/#{alert['repository']['name']}/blob/#{location_details['commit_sha']}/#{location_details['path']}#L#{location_details['start_line']}"
          note = 'Secret found in commit, refer to the GitHub URL column'
        elsif !location_details['pull_request_review_comment_url'].nil?
          pr_review_comment_info = JSON.parse(fetch_data(location_details['pull_request_review_comment_url']))
          file_path = pr_review_comment_info['path']
          committer_name = pr_review_comment_info['user']['login']
          committer_email = pr_review_comment_info['user']['html_url']
          committer_date = pr_review_comment_info['created_at']
          gh_url = pr_review_comment_info['html_url']
          note = 'Secret found in pull request review comment, refer to the GitHub URL column'
        else
          note = "Something's gone wrong! You'll need to refer to the Alert URL: #{alert['html_url']}."
        end

        puts 'Working on: ' + alert['html_url']

        repo_name = alert['repository']['full_name'].split('/').last

        alert_data = {
          number: alert['number'],
          ruleid: alert['secret_type_display_name'],
          file: file_path,
          org: org_name,
          repository: repo_name,
          secret: alert['secret'],
          validity: alert['validity'],
          state: alert['state'],
          resolution: alert['resolution'],
          commit: location_details['commit_sha'],
          startline: location_details['start_line'],
          endline: location_details['end_line'],
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
    csv << ['Alert Number', 'RuleID', 'File', 'Org', 'Repo', 'Secret', 'Validity', 'State', 'Resolution', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL', 'Resolution Comment', 'Committer Name', 'Committer Email', 'Committer Date', 'Note']
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
