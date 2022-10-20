#!/usr/bin/env ruby
# script to list repos in a github org
require 'pry'
require 'octokit'

ORG = ''

# use github octokit to get public repos in an organization
# for private repos, need a PAT:
# client = Octokit::Client.new(:access_token => "ghp_")

client = Octokit::Client.new()
client.auto_paginate = true
repos = client.org_repos(ORG)
clone_urls = []
puts "found #{repos.count} repos in #{ORG} org"
repos.each do |repo|
  # puts repo.name
  puts "git clone #{repo.clone_url}"

end
