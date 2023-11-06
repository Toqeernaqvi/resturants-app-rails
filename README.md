# README

This README would normally document whatever steps are necessary to get the
application up and running.

* default branch: develop

* Docker setup (recommended)
  Dependencies: docker and docker-compose
  Configuration:
    copy .env.sample file to .env and set the values by looking into docker-compose.yml database environment variables
    copy config/database.yml.sample file to config/database.yml and set the values
    using terminal cd to project root directory and then run the following command:
    docker-compose up

* Manual setup

Things you may want to cover:

* Ruby version
  2.4.0

* Rails version
  5.1.6

* System dependencies
  Ubuntu

* Configuration
  copy .env.sample file to .env and set the values
  copy config/database.yml.sample file to config/database.yml and set the values

* Database creation
  postgresql

* Database initialization
  rails db:create
  rails db:migrate
  rails db:seed

* How to run the test suite


* Services (job queues, cache servers, search engines, etc.)


* Deployment instructions
  cap staging deploy