#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install --without development test

# Install node modules with production flag
npm install --production
yarn install --production

# Build JavaScript with production optimization
NODE_ENV=production yarn build
NODE_ENV=production yarn build:css

# Precompile assets with production settings
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=production bundle exec rake assets:clean

# Database setup
RAILS_ENV=production bundle exec rake db:migrate
