#!/usr/bin/env ruby
# ruby script find contributors for a set of github repos
require 'csv'
require 'json'
require 'pry'
require 'octokit'

RESULTS_FILE = 'repo_contributors.csv'.freeze

# repo_dirs = []
repo_dirs = Dir.glob('*').select { |f| File.directory? f }
puts repo_dirs

# open csv file to write headers
CSV.open("orphanedrepos.csv", "wb") do |csv|
    csv << %w[repo login contributions html_url type]
end

repo_dirs.each do |dir|
  # use octokit to get top contributors for each repo
  client = Octokit::Client.new(:access_token => ENV['GITHUB_DTKT_TOKEN'])
  contributors = client.contributors(dir)

  CSV.open(RESULTS_FILE, "a+") do |csv|
      contributors.each do |contributor|
          csv << [dir, contributor.login, contributor.contributions, contributor.html_url, contributor.type]
      end
  end
end
