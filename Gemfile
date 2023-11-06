source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.6', '>= 5.1.6.1'

gem 'dotenv-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.2', '>= 1.2.1'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# gem 'braintree', '~> 2.61', '>= 2.61.1'
gem 'whenever', '~> 0.9.4'
gem 'rubyzip', '>= 1.0.0'
gem 'geocoder', '~> 1.3', '>= 1.3.7'
gem 'responders'
gem 'htmltoword'
gem 'airbrake', '~> 9.4', '>= 9.4.5'
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem 'ckeditor', '~> 4.2', '>= 4.2.4'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
gem 'enumerize'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'cancancan', '~> 1.16.0'
gem 'google_places'

group :development, :test do
  gem 'faker'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 3.6'
  gem 'factory_bot_rails', '4.8.2'
  gem 'capistrano',         require: false
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'pry-rails'
  gem 'letter_opener'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'bootstrap', '~> 4.0.0'
gem 'devise'
gem 'high_voltage'
gem 'jquery-rails'
gem 'devise_token_auth'
# gem 'therubyracer', :platform=>:ruby

gem 'activeadmin'
gem 'arctic_admin'
gem 'activeadmin_addons'
gem 'simple_form'
# gem "paranoia", "~> 2.2"

gem "mini_magick"
gem 'carrierwave', '~> 1.0'
gem "fog-aws"
gem 'roo'
gem 'onfleet-ruby'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary' #sudo apt-get install wkhtmltopdf
gem 'rack-cors', :require => 'rack/cors'
gem 'httparty'
gem 'sidekiq'
gem 'paper_trail'
gem 'paper_trail-association_tracking'
gem 'gmaps4rails'
gem 'activeadmin_trumbowyg'
gem "chartkick"
gem 'twilio-ruby'
gem 'aws-sdk-s3'
gem 'rest-client'
gem "slack-notifier"
gem "quickbooks-ruby"
gem "zendesk_api"
gem 'searchkick'
gem 'timezone', '~> 1.0'
gem 'activerecord-import'
gem 'jwt'
gem 'friendly_id'
gem 'shortener'
gem 'caxlsx'
gem 'caxlsx_rails'
gem 'acts-as-taggable-on'