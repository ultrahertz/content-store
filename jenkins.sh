#!/bin/bash -x
set -e

export RAILS_ENV=test

git clean -fdx
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake db:mongoid:drop
COVERAGE=on bundle exec rake ci:setup:rspec default
