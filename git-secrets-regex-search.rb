#!/usr/bin/env ruby
# script to run git secrets for a set of repositories
# https://github.com/awslabs/git-secrets
# Example regexes
# IP Address
# \b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b
#
# Email
# \b[\w][\w+.-]+(@|%40)[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\b
#
# Phone Number
# ^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$
#
# SSN
# \b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b
#
# git secrets --add --global '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
# git secrets --add --global '\b\d{3}[\s+-]\d{2}[\s+-]\d{4}\b'
# git secrets --add --global '(\b[3456]\d{3}[\s+-]\d{4}[\s+-]\d{4}[\s+-]\d{4}\b)|(\b[3456]\d{15}\b)'
# git secrets --add --global '\b[\w][\w+.-]+(@|%40)[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\b'

require 'csv'
require 'pry'
require 'open3'

GH_ORG = "<orggoeshere>".freeze
RESULTS_FILE = "gitsecrets-scan-results.csv".freeze

# repo_dirs = [ '<project_location>' ]
repo_dirs = Dir.glob('*').select { |f| File.directory? f }
puts repo_dirs

# open csv to write results
CSV.open(results_file, "wb") do |csv|
  csv << %w[repo file line url blob]
end

# run git secrets on each directory
repo_dirs.each do |dir|
  repo = dir.split("/")[0]

  puts "Running git secrets on #{dir}"

  stdout, stderr, status = Open3.capture3("cd #{dir} && git secrets --scan")

  puts stdout
  puts stderr
  puts status

  if stderr != ""
    file = stderr.split(":")[0]
    line = stderr.split(":")[1].split(":")[0]

    url = "https://github.com/#{GH_ORG}/#{repo}/blob/main/#{file}#L#{line}"
    # blob = stderr.split(":")[1].split(":")[1]
    # binding.pry
    # break
    # write to csv
    CSV.open(RESULTS_FILE, "a") do |csv|
      csv << [repo, file, line, url, stderr]
    end
  end
end
