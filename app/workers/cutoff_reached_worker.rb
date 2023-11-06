class CutoffReachedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cutoff_reached_queue

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Cutoff Reached Job for runningmenu_id: #{runningmenu.id}"
        email = ScheduleMailer.cutoff_at_reached([runningmenu])
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        Order.assign_groups(runningmenu) if runningmenu.company.enable_grouping_orders
        puts "Cutoff Reached Reminder End - #{Time.current}"

        OrdersDetailAtCutoffJob.perform_later(runningmenu)
        runningmenu_addresses = runningmenu.addresses.active
        runningmenu_addresses.each do |address|
          puts "Sending cutoff sms for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          TwilioSmsJob.perform_later(runningmenu_id, address.id, 'cutoff') unless address.contact_numbers.blank?
          puts "Order History At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          OrdersDetailToRestaurantAtCutoffJob.perform_now(runningmenu, address)
        end
        runningmenu.assign_attributes(cutoff_reached_job_status: Runningmenu.cutoff_reached_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.assign_attributes(cutoff_reached_job_status: Runningmenu.cutoff_reached_job_statuses[:not_processed], cutoff_reached_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end
  
end