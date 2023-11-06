#!/bin/bash

# exit if ret status not 0
set -o errexit

readonly RAILS_CMD="$(pwd)/bin/rails"
readonly BASHRC="$HOME"/.bashrc

source_rc() {
  . "$BASHRC"
}

configure_db() {
    echo "*********** running migration for $RAILS_ENV ***********"
    #"$RAILS_CMD" db:migrate:ignore_concurrent
    #"$RAILS_CMD" db:create
    # "$RAILS_CMD" db:schema:load
    "$RAILS_CMD" db:migrate
    #"$RAILS_CMD" db:seed
    #"$RAILS_CMD" assets:precompile
}

install_nodejs() {
  echo "*********** installing nodejs ***********"
  source_rc
  nvm install 10.13
}

install_node_modules() {
  echo "*********** installing yarn and node modules ***********"
  curl -o- -L https://yarnpkg.com/install.sh | bash
  source_rc
  yarn
}

install_bundle() {
  echo "*********** doing bundle install ***********"
  gem install bundler:1.17.3
  bundle install
}

run_sidekiq_cron() {
  echo "*********** Copying environment ***********"
  printenv | grep -v "no_proxy" >> /etc/environment
  echo "*********** Installing crontab start ***********"
  bundle exec whenever --update-crontab -i "chowmill_$RAILS_ENV" --set environment="$RAILS_ENV"
  echo "*********** Starting Sidekiq Daemon ***********"
  sidekiq -e "$RAILS_ENV" -d -L /application/log/sidekiq.log -C /application/config/sidekiq.yml -P /application/tmp/pids/sidekiq-0.pid
  echo "*********** Running Crontab Service ***********"
  cron -f
}

run_cron() {
  printenv | grep -v "no_proxy" >> /etc/environment
  cron -f
}

boot_server() {
  if [ "$INSTALL" = "sidekiq-cron" ]; then
    run_sidekiq_cron
  else
    echo "*********** Running application on port 3000 ***********"
    "$RAILS_CMD" s --binding 0.0.0.0 -p 3000
  fi
}

main() {
  echo "*********** bootstrapping dependencies ***********"
  rm tmp/pids/server.pid || true
  install_bundle

  [ ! -d "/application/shared" ] && mkdir /application/shared
  chmod -R 0777 /application/shared/

  [ ! -d "/application/log" ] && mkdir /application/log
  [ ! -f "/application/log/sidekiq.log" ] && touch /application/log/sidekiq.log
  [ ! -d "/application/tmp/pids" ] && mkdir -pv /application/tmp/pids/
  [ ! -f "/application/tmp/pids/sidekiq-0.pid" ] && touch /application/tmp/pids/sidekiq-0.pid

  [ ! -d "/application/public/ordersummary" ] && mkdir /application/public/ordersummary
  [ ! -d "/application/public/download_pdfs" ] && mkdir /application/public/download_pdfs
  [ ! -d "/application/public/labels_csvs" ] && mkdir /application/public/labels_csvs
  [ ! -d "/application/public/fax_summary" ] && mkdir /application/public/fax_summary


  configure_db

  boot_server
}
main
