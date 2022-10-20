# uses phabricator api to list all repos in phabricator with clone links
# and writes them to a file
# requires python3 and phabricator python module
# pip3 install phabricator
import os
import sys
import json
import phabricator

phab = phabricator.Phabricator()
phab.update_interfaces()

repos = phab.diffusion.repository.search(attachments={"uris": True })

count = 0
for repo in repos['data']:
  # print(repo['fields']['name'])

  clone_url = repo['attachments']['uris']['uris'][0]['fields']['uri']['raw']
  # if git_clone_name does not start with git@, skip it
  if not clone_url.startswith('git@'):
    continue
  git_clone_name = 'git clone ' + clone_url
  print(git_clone_name)
  count += 1

  while repos['cursor']['after'] != None:
    repos = phab.diffusion.repository.search(attachments={"uris": True }, after=repos['cursor']['after'])
    for repo in repos['data']:
      # if attachments is empty, skip
      if not repo['attachments']['uris']['uris']:
        continue

      clone_url = repo['attachments']['uris']['uris'][0]['fields']['uri']['raw']

      # if git_clone_name does not start with git@, skip it
      if not clone_url.startswith('git@'):
        continue


      git_clone_name = 'git clone ' + clone_url
      print(git_clone_name)

      count += 1

      if repos['cursor']['after'] == None:
        break


      # print("after: " + repos['cursor']['after'])
      print("Total repos: " + str(count))
