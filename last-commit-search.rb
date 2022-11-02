#!/usr/bin/env ruby
# ruby script to find file types in repos
require 'pry'

RESULTS_FILE = "commit_date_results.csv"

# repo_dirs = []
repo_dirs = Dir.glob('*').select { |f| File.directory? f }
puts repo_dirs

repo_dirs.each do |dir|
  output = `cd #{dir} && git log -1 --format=%cd`
#   puts "https://github.com/dropbox/blob/master/#{output}"
  # output = `cd #{dir} && git ls-tree -r main --name-only | grep -E '.*\.(pdf|doc|docx|txt|xls|xlsx|csv|ppt|pptx|rtf|odt|ods|odp|odg|odf|odb|sql|dump|sqldump|db)$'`
  # puts "https://github.com/dropbox/blob/main/#{output}"
end
