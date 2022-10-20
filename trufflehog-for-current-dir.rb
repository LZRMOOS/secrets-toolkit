#!/usr/bin/env ruby
# This script is intended to be run from the root dir with git repos as subdirs
# It will run trufflehog on each repo and output the results to a file in the
# repo dir named trufflehog_scan_results.csv
require 'csv'
require 'open3'
require 'pry'

RESULTS_FILE = 'trufflehog-scan-results.csv'.freeze

# writer csv headers
CSV.open(RESULTS_FILE, "wb") do |csv|
  csv << %w[repo results]
end

# get root directory names in the current directory
current_repo_dirs = Dir.glob('*').select { |f| File.directory? f }
puts current_repo_dirs

# run truffle hog on each directory
current_repo_dirs.each do |dir|
  puts "-----------------------------"
  puts "Running trufflehog on #{dir}"

  stdout, stderr, status = Open3.capture3("trufflehog filesystem --no-update --directory=#{dir}")

  puts "stdout: #{stdout}"
  puts "stderr: #{stderr}"
  puts "status: #{status}"
  puts "-----------------------------"

  # write results to csv
  if stdout == ''
    puts "No results for #{dir}"
  else
    # try to write to csv, if fail print error in csv
    begin
      # write results to csv
      CSV.open(RESULTS_FILE, "a") do |csv|
        csv << [dir, stdout]
      end
    rescue StandardError => e
      puts "Error writing to csv: #{e}"
      CSV.open(RESULTS_FILE, "a") do |csv|
        csv << [dir, "Error writing to csv: #{e}"]
      end
    end
  end
end
