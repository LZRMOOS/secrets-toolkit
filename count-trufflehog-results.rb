#!/usr/bin/env ruby
require 'csv'
require 'pry'

TRUFFLEHOG_CSV_FILE = "trufflehog-scan-results-phabricator.csv"

# read trufflehog csv results file and count the number of times "Found unverified result" appears in the results column and add new column with the count
CSV.foreach(TRUFFLEHOG_CSV_FILE) do |row|
    repo = row[0]
    results = row[1]
    count = results.scan(/Found unverified result/).count
    puts "#{repo},#{count}"
end
