class CronUpdaterJob < ApplicationJob
  queue_as :cron_updater

  def perform
    system "whenever --update-crontab -i chowmill_#{Rails.env} --set environment='#{Rails.env}'" if system "whenever task: bundle exec whenever -c chowmill_#{Rails.env}"
  end
end
