#!/usr/bin/env ruby
# script to get secret scanning alerts for a github repository and save results to a csv file
require 'pry'
require 'octokit'
require 'csv'

# github personal access token with repo scope or get from ENV
ACCESS_TOKEN = '<GITHUB_PAT>'
# name of organization to get alerts for
ORG = '<ORGANIZATION_NAME>'
# name of repository to get alerts for
REPO = '<REPOSITORY_NAME>'
# name of csv file to save results to
RESULTS_FILE = "ghas-results-#{REPO}.csv"
# number of pages to get
PAGES = 3
# number of alerts per page
PER_PAGE = 100

client = Octokit::Client.new(:access_token => ACCESS_TOKEN)
client.auto_paginate = true

# open csv file to write headers
CSV.open(RESULTS_FILE, "wb") do |csv|
    csv << %w[number created_at updated_at url html_url locations_url state secret_type secret_type_display_name secret resolution resolved_by resolved_at resolution_comment push_protection_bypassed push_protection_bypassed_by push protection_bypassed_at]
end

page = 1

# get the alerts for the repo
while page < PAGES do
  alerts = client.get("/repos/#{ORG}/#{REPO}/secret-scanning/alerts?per_page=#{PER_PAGE}&page=#{page}")
  puts alerts.size
  alerts.each do |alert|
    CSV.open(RESULTS_FILE, "a+") do |csv|
        csv << [ alert.number, alert.created_at, alert.updated_at, alert.url, alert.html_url, alert.locations_url, alert.state, alert.secret_type, alert.secret_type_display_name, alert.secret, alert.resolution, alert.resolved_by, alert.resolved_at, alert.resolution_comment, alert.push_protection_bypassed, alert.push_protection_bypassed_by, alert.push, alert.protection_bypassed_at ]
    end
  end
  page += 1
end
