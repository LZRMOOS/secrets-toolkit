#!/usr/bin/env ruby
# ruby script find contributors for a set of github repos
require 'csv'
require 'json'
require 'pry'
require 'octokit'

RESULTS_FILE = 'repo_contributors.csv'.freeze

repo_list = [
    # <repos_here>
].uniq!

# open csv file to write headers
CSV.open(RESULTS_FILE, "wb") do |csv|
    csv << %w[repo login name contributions html_url type]
end

client = Octokit::Client.new(:access_token => ENV['GITHUB_DTKT_TOKEN'])

# parse repo org and name from url
repo_list.map! do |repo|
    repo.split('/').last(2).join('/')
    end

repo_list.each do |repo|
  # use octokit to get top contributors for each repo
  contributors = client.contributors(repo)

  CSV.open(RESULTS_FILE, "a+") do |csv|
      contributors.each do |contributor|
          contributor.name = client.user(contributor.login).name
          csv << [repo, contributor.login, contributor.name, contributor.contributions, contributor.html_url, contributor.type]
      end
  end
end
