
set :output, "log/cron_log.log"
env :PATH, ENV['PATH']
require_relative './environment'

def local(utc_time)
  (utc_time.to_time + Time.current.in_time_zone('US/Pacific').formatted_offset.to_time.hour.hours).strftime("%I:%M%P")
end

every 2.days do
  rake 'log:clear'
end

every 1.month do
  rake 'email_logs:remove_old_logs'
end

# every 1.day, at: local('3pm') do #will run at 3pm
#   rake 'ordertransaction:orderpayment'
# end

# every 1.day, at: local('2pm') do #will run at 2pm
#   rake 'pendingtotalcalculate:pending_total'
# end

# every 1.day, at: '3:00am' do
  # rake 'restaurant_payout:pay'
# end

# every 1.day, at: local('12am') do #will run at 12am
#   rake 'restaurant_payout:set_status_to_due'
# end

every 1.day, at: local('12:31am') do #will run at 12:31am
  rake 'invoice_check:invoice_check'
  rake 'invoice_check:restaurant_billing_check'
end

# every 10.minutes do
  # All crons moved to sidekiq
  # rake 'foodfeedback:orderfeedback'
  # rake 'cutoffreminder:cutoff_reminder'
  # rake 'restaurant_payout:generate'
  # rake 'onfleet_tasks:onfleet_task'
  # rake 'collective:ten_minutes'
# end

every 1.day, at: ['12:30 am', '1:30 am', '2:30 am', '3:30 am', '4:30 am', '5:30 am', '6:30 am', '7:30 am', '8:30 am', '9:30 am', '10:30 am', '11:30 am', '12:30 pm', '1:30 pm', '2:30 pm', '3:30 pm', '4:30 pm', '5:30 pm', '6:30 pm', '7:30 pm', '8:30 pm', '9:30 pm', '10:30 pm', '11:30 pm'] do
  rake 'invoice:generate'
end

every ENV["MEETING_EMAILS_INTERVAL"].to_i.minutes do
  rake 'restaurant_alert:restaurant_alert'
end

# every 1.minutes do
  # cutoff task moved to sidekiq job
  # rake 'cutoffreached:cutoffreached_reminder'
  # rake 'cutoffreached:buffet_delivery_reminder'
  # cutoff task moved to sidekiq job

  # # rake 'orders_at_cutoff:orders_at_cutoff'
  # rake 'orders_at_admin_cutoff:orders_at_admin_cutoff'
  # rake 'email_log_send_emails:send_emails'
# end

every 50.minutes do
  rake 'quickbooks:refresh_token'
end

# every 5.minutes do
#   rake 'faxes:retries'
# end

# every 1.day, at: local('2am') do
#   rake 'recurring:schedulers'
# end
# every :sunday, :at => local('12pm') do #will run at 12pm
#   rake 'invoice:generate_weekly'
# end

# every :sunday, :at => '7pm' do #will run at 12pm
#   rake 'invoice:generate_weekly'
# end

# every :sunday, :at => local('12:10pm') do #will run at 12:10pm
#   rake 'invoice_check:weekly_invoice_check'
# end

# this cron will run on saturday 00:00:00 pdt-7 time zone
# every :saturday, :at => local('12am') do #will run at 12am
#   rake 'restaurant_payout:set_final_status'
# end

every 1.hours do
  # rake 'pendingtotalcalculate:pending_total'
  # rake 'ordertransaction:orderpayment'
  # rake 'restaurant_payout:set_final_status'
  # rake 'restaurant_payout:set_status_to_due'
  # rake 'recurring:schedulers'
  # rake 'dashboard_metric:highest_rated_restaurants'
  # rake 'dashboard_metric:lowest_rated_restaurants'
  # rake 'dashboard_metric:highest_rated_dishes'
  # rake 'dashboard_metric:lowest_rated_dishes'
  rake 'collective:hourly'
end

Report.all.each do |report|
  if report.hourly?
    every (report.scheduled_time).hour do
      rake report.orders_not_invoiced? ? 'report:orders_not_invoiced' : (report.orders_not_billed? ? 'report:orders_not_billed' : 'report:average_take_rate')
    end
  elsif report.daily?
    every (report.scheduled_time).day, at: local('3am') do
      rake report.orders_not_invoiced? ? 'report:orders_not_invoiced' : (report.orders_not_billed? ? 'report:orders_not_billed' : 'report:average_take_rate')
    end
  elsif report.weekly?
    every (report.scheduled_time).week, at: local('3am') do
      rake report.orders_not_invoiced? ? 'report:orders_not_invoiced' : (report.orders_not_billed? ? 'report:orders_not_billed' : 'report:average_take_rate')
    end
  elsif report.monthly?
    every (report.scheduled_time).month, at: local('3am') do
      rake report.orders_not_invoiced? ? 'report:orders_not_invoiced' : (report.orders_not_billed? ? 'report:orders_not_billed' : 'report:average_take_rate')
    end
  elsif report.yearly?
    every :year, at: local('3am') do
      rake report.orders_not_invoiced? ? 'report:orders_not_invoiced' : (report.orders_not_billed? ? 'report:orders_not_billed' : 'report:average_take_rate')
    end
  end
end
unless Report.find_by_report_type(:orders_not_invoiced).present?
  every 1.day, at: local('3am') do
    rake 'report:orders_not_invoiced'
  end
end
unless Report.find_by_report_type(:orders_not_billed).present?
  every 1.day, at: local('3am') do
    rake 'report:orders_not_billed'
  end
end
unless Report.find_by_report_type(:average_take_rate).present?
  every 1.day, at: local('3am') do
    rake 'report:average_take_rate'
  end
end
