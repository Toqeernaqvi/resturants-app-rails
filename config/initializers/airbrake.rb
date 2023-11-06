require 'airbrake'

Airbrake.configure do |c|
  c.project_id = ENV['AIRBRAKE_PROJECT_ID']
  c.project_key = ENV['AIRBRAKE_PROJECT_KEY']
  c.environment = Rails.env
  c.ignore_environments = %w(development test)
  Rails.env == "production" ? c.performance_stats = true : c.performance_stats = false
end
