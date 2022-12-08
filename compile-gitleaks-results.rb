#!/usr/bin/env ruby

require 'csv'
require 'open3'
require 'pry'
#TODO: append all gitleaks files to one gitleaks-summary.csv file.
#    this will require a header row to be removed from each gitleaks file
#    and then the files appended to the summary file
# ensure GITLEAKS_RESULTS_PATH is empty of all csvs except results

GITLEAKS_RESULTS_PATH = '<path>'.freeze
GITLEAKS_SUMMARY_FILE = 'gitleaks-summary.csv'.freeze

# create summary csv headers
CSV.open(GITLEAKS_SUMMARY_FILE, 'wb') do |csv|
  csv << %w[RuleID Commit File Repo Secret Match StartLine EndLine StartColumn EndColumn Author Message Date Email Fingerprint]
end

# read csv files, delete header row, and write to summary file with filename as first column
Dir.glob("#{GITLEAKS_RESULTS_PATH}/*_gitleaks.csv").each do |file|
  puts "Processing #{file}"
  repo_name = file.split('/').last.split('_').first
  puts "repo_name: #{repo_name}"

  begin
  # read csv file and write to summary file without header
  CSV.foreach(file, headers: true) do |row|
    # TODO: add repo_url to row as well
    row[3] = repo_name
    CSV.open(GITLEAKS_SUMMARY_FILE, 'a+') do |csv|
      csv << row
    end
  end
  rescue CSV::MalformedCSVError => e
    puts "Error for #{repo_name}: #{e}"
  end
end
