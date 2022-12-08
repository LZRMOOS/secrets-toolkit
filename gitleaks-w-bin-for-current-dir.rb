#!/usr/bin/env ruby
require 'csv'
require 'open3'
require 'pry'

GITLEAKS_BIN = "/home/weid/src/gitleaks_bin/gitleaks"
# set repos_dir if custom path desired
repos_path = ""

if repos_path == ""
  # get root directory names in the current directory
  github_repo_dirs = Dir.glob('*').select { |f| File.directory? f }
else
  # get root directory names in the custom directory
  github_repo_dirs = Dir.glob("#{repos_path}/*").select { |f| File.directory? f }
end

github_repo_dirs.each do |repo|
  puts "-------------------------------------"
  puts "Scanning for secrets with gitleaks on #{repo}"

  stdout, stderr, status = Open3.capture3("#{GITLEAKS_BIN} detect --source #{repo} -v -f csv -r #{repo}_gitleaks.csv")


  puts "stdout: #{stdout}"
  puts "stderr: #{stderr}"
  puts "status: #{status}"
  puts "-------------------------------------"
end
