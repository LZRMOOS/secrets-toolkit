require 'csv'
require 'date'
require 'json'
require 'open-uri'

ACCESS_TOKEN = ENV['GH_PAT']
USERNAME = ENV['USER']
DATE = Date.today.to_s

def fetch_data(url)
  URI.open(url, 'Accept' => 'application/vnd.github+json',
                'Authorization' => "Bearer #{ACCESS_TOKEN}",
                'X-GitHub-Api-Version' => '2022-11-28').read
end

def get_all_repos_for_organization(org_name)
  puts "Fetching all repos for organization: #{org_name}"
  all_repo_names = []
  page = 1
  loop do
    repos = JSON.parse(fetch_data("https://api.github.com/orgs/#{org_name}/repos?page=#{page}"))

    break if repos.empty?

    all_repo_names.concat(repos.map { |repo| repo['name'] })
    page += 1
  end
  puts "Retrieved #{all_repo_names.size} repos for organization: #{org_name}"
  all_repo_names
end

def enumerate_secret_alerts_for_repo(org_name, repo_name)
  alert_id = 1
  secret_alerts = []
  loop do 
    begin
      secret_alert_json = JSON.parse(fetch_data("https://api.github.com/repos/#{org_name}/#{repo_name}/secret-scanning/alerts/#{alert_id}"))
    rescue OpenURI::HTTPError => e
      break
    end

    break if secret_alert_json.empty?

    secret_alerts << secret_alert_json
    alert_id += 1
  end

  secret_alerts
end

def get_alerts_for_organization(org_name)
  puts "Fetching GHAS Secret Scan Results for #{org_name} @ #{Time.now}\n------------------------------------------------------------------\n"
  alerts_data = []
  repo_names = get_all_repos_for_organization(org_name)

  repo_names.each do |repo_name| 
    secret_alerts = enumerate_secret_alerts_for_repo(org_name,repo_name)
    secret_alerts.each do |alert|
      locations_url = alert['locations_url']
      next if locations_url.empty?

      locations_json = JSON.parse(fetch_data(locations_url))

      locations_json.each do |location|
        location_details = location['details']
        note, committer_date, committer_email, gh_url, file_path = ''
        if !location_details['issue_comment_url'].nil?

          issue_comment_info = JSON.parse(fetch_data(location_details['issue_comment_url']))
          file_path = 'Refer to GitHub URL'

          committer_login = issue_comment_info['user']['login']
          committer_email = issue_comment_info['user']['html_url']
          committer_date  = issue_comment_info['created_at']

          gh_url = issue_comment_info['html_url']
          note = 'Secret found in issue comment, refer to the GitHub URL column'
        elsif !location_details['commit_sha'].nil?
          commit_ref = JSON.parse(fetch_data("https://api.github.com/repos/#{org_name}/#{repo_name}/commits/#{location_details['commit_sha']}"))
          file_path = location_details['path']

          committer_login = commit_ref['author'].nil? ? commit_ref['commit']['committer']['name'] : commit_ref['author']['login']
          committer_email = commit_ref['commit']['committer']['email']
          committer_date  = commit_ref['commit']['committer']['date']

          gh_url = "https://github.com/#{org_name}/#{repo_name}/blob/#{location_details['commit_sha']}/#{location_details['path']}#L#{location_details['start_line']}"
          note = 'Secret found in commit, refer to the GitHub URL column'
        elsif !location_details['pull_request_review_comment_url'].nil?
          pr_review_comment_info = JSON.parse(fetch_data(location_details['pull_request_review_comment_url']))
          file_path = pr_review_comment_info['path']

          committer_login = pr_review_comment_info['user']['login']
          committer_email = pr_review_comment_info['user']['html_url']
          committer_date  = pr_review_comment_info['created_at']

          gh_url = pr_review_comment_info['html_url']
          note = 'Secret found in pull request review comment, refer to the GitHub URL column'
        else
          note = "Something's gone wrong! You'll need to refer to the Alert URL: #{alert['html_url']}."
        end

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
          committer_login: committer_login,
          committer_email: committer_email,
          committer_date: committer_date,
          note: note
        }

        alerts_data << alert_data
      end
    end
    puts "Found #{secret_alerts.size} alerts for repo: #{repo_name}"
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
  csv_file = "#{org_name}-#{DATE}-all-ghasss-results-by-#{USERNAME}.csv"

  CSV.open(csv_file, 'w') do |csv|
    csv << ['Alert Number', 'RuleID', 'File', 'Org', 'Repo', 'Secret', 'Validity', 'State', 'Resolution', 'Commit SHA', 'Start Line', 'End Line', 'Alert URL', 'GitHub URL', 'Resolution Comment', 'Committer Login', 'Committer Email', 'Committer Date', 'Note']
    alerts_data.each do |alert_data|
      csv << alert_data.values
    end
  end

  puts "#{alerts_data.size} Secret scanning alerts for #{org_name} exported to #{csv_file}"
end

if ARGV.empty?
  puts 'Please provide either an organization name or a file containing organization names.'
else
  input = ARGV[0]

  if File.file?(input)
    process_organizations_from_file(input)
  else
    alerts_data = get_alerts_for_organization(input)
    export_to_csv(alerts_data, input)
  end
end
