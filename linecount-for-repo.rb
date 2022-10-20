#!/usr/bin/env ruby
# ruby script to find how many lines of code are in a set of repos
# https://github.com/AlDanial/cloc
require 'open3'
require 'pry'

repos_dir = '<repos_path>'.freeze

# find number of lines of code for multiple github repos and count the total lines of code
puts "-----------------------------"
puts "Counting lines of code for #{dir}"

stdout, stderr, status = Open3.capture3("cloc #{dir}")

puts "stdout: #{stdout}"
puts "stderr: #{stderr}"
puts "status: #{status}"
puts "-----------------------------"
