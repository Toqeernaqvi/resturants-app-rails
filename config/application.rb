require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chowmill
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.assets.precompile += ['buffet_pdf.css']
    config.assets.precompile += Ckeditor.assets
    config.assets.precompile += %w( ckeditor/* ckeditor_assets/* *.png *.jpg *.jpeg *.gif img/*)
    config.time_zone = ENV["TIMEZONE"]
    config.eager_load_paths += %W(#{config.root}/app/workers)
    # config.eager_load_paths << Rails.root.join('lib')
    config.active_job.queue_adapter = :sidekiq
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  	config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          expose: ['access-token', 'expiry', 'token-type', 'uid', 'client'],
          methods: [:get, :post, :options, :delete, :put]
      end
    end
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'DENY'
    }
  end
end
