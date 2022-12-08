#!/usr/bin/env ruby
# this is a script to add Github repo URLs to the results of a gitleaks scan
require 'csv'
require 'pry'

GITLEAKS_CSV_FILE = "gitleaks-scan-results-server.csv"
ORG = "dropbox"

# output = `gitleaks detect --source #{dir} -v -f csv -r #{dir.gsub("/", "")}_gitleaks.csv`
# read csv file and add a new column with a link to the commit
CSV.foreach(GITLEAKS_CSV_FILE) do |row|
#   repo = row[0]
#   commit = row[2]
  file = row[2]
  line = row[6]

    link = "https://sourcegraph.pp.#{ORG}.com/server/-/blob/#{file}?L#{line}"
    # https://sourcegraph.pp.dropbox.com/server/-/blob/go/src/dropbox/vortex2/server/itest/data/itest_alerts.pyst

    puts link
end
