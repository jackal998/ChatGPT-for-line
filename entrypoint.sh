#!/bin/sh
cd /app
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:migrate

bundle exec rails s -e production -b 0.0.0.0 -p 8080
