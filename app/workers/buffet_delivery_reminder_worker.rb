class BuffetDeliveryReminderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :buffet_delivery_reminder
  #Task for Reminder of Day before buffet delivery
  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "REMINDER: Order History At Cutoff for Buffet scheduler #{runningmenu.id} - #{Time.current}"
        runningmenu.addresses.active.each do |address|
          puts "REMINDER: Order History At Cutoff start for address #{address.id} and runningmenu #{runningmenu.id} - #{Time.current}"
          address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: address.id)
          user_orders_present = runningmenu.orders.active.joins(:user).where("users.user_type IN(#{User.user_types[:company_user]}, #{User.user_types[:company_manager]}, #{User.user_types[:unsubsidized_user]}) AND orders.restaurant_address_id= ? OR orders.share_meeting_id IS NOT NULL", address.id).exists?
          if user_orders_present
            orders = Order.order_summary_user(runningmenu, false, 0, 0, address.id)
          else
            orders = Order.order_summary(runningmenu, false, 0, 0, address.id)
          end
          # puts "REMINDER: Order History At Cutoff found #{orders.count} orders of quantity sum: #{orders.sum{|o| o.quantity} } for address #{address.id} - #{Time.current}"
          if orders.present?
            file_name = "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')} #{runningmenu.id}"
            summary_contacts = address.summary_contacts
            if summary_contacts.present?
              email = ScheduleMailer.orders_for_restaurants_buffet_reminder(runningmenu, orders, address, summary_contacts)
              email_log = EmailLog.new(sender: email.from.first, cc: email.cc&.join(', '), subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
              email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: address_runningmenu.summary_pdf)
              email_log.save
            else
              puts "REMINDER: No contacts Found or scheduler in buffet style for address #{address.id} and scheduler #{runningmenu.id} email will go to order email- #{Time.current}"
              email = ScheduleMailer.orders_for_restaurants_buffet_reminder(runningmenu, orders, address, nil)
              email_log = EmailLog.new(sender: email.from.first, cc: email.cc&.join(', '), subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
              email_log.logs_attachments.new(attachment_file_name: file_name + '.pdf', attachment: address_runningmenu.summary_pdf)
              email_log.save
            end
          end
        end
        runningmenu.assign_attributes(buffet_delivery_reminder_job_status: Runningmenu.buffet_delivery_reminder_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.assign_attributes(buffet_delivery_reminder_job_status: Runningmenu.buffet_delivery_reminder_job_statuses[:not_processed], buffet_delivery_reminder_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end

end