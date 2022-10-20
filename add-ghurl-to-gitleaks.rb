#!/usr/bin/env ruby
# this is a script to add Github repo URLs to the results of a gitleaks scan
require 'csv'
require 'pry'

GITLEAKS_CSV_FILE = "<path>.csv"
SPECIAL_REPO = "custom-strategy"
GITHUB_ORG = "<orggoeshere>"

# output = `gitleaks detect --source #{dir} -v -f csv -r #{dir.gsub("/", "")}_gitleaks.csv`
# read csv file and add a new column with a link to the commit
CSV.foreach(GITLEAKS_CSV_FILE) do |row|
  repo = row[0]
  commit = row[2]
  file = row[3]
  line = row[7]

  if repo == SPECIAL_REPO
    link = "https://github.com/#{SPECIAL_REPO}/blob/#{commit}/#{file}#L#{line}"
  else
    link = "https://github.com/#{GITHUB_ORG}/#{repo}/blob/#{commit}/#{file}#L#{line}"
  end
  puts link
end
