class AdminCutoffDayBeforeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :admin_cutoff_day_before_reminder

  def perform(runningmenu_id)
    # Commented out to further investigate
    # runningmenu = Runningmenu.find runningmenu_id
    # begin
    #   puts "Admin Cutoff Day Before Reminder Job for runningmenu_id: #{runningmenu.id}"
    #   admins = CompanyAdmin.active.joins("LEFT JOIN orders ON users.id = orders.user_id AND orders.status = #{Order.statuses[:active]} AND orders.runningmenu_id = #{runningmenu.id}").where("orders.user_id IS NULL AND users.company_id = ? AND users.address_id = ? AND users.admin_cutoff_day_#{runningmenu.runningmenu_type}_reminder = ?", runningmenu.company_id, runningmenu.address_id, true).uniq
    #   admins.each do |admin|
    #     email = OrderMailer.no_order_placed(admin, runningmenu)
    #     EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    #   end
    #   runningmenu.update_attributes(admin_cutoff_day_before_job_status: Runningmenu.admin_cutoff_day_before_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
    # rescue StandardError => e
    #   runningmenu.update_attributes(admin_cutoff_day_before_job_status: Runningmenu.admin_cutoff_day_before_job_statuses[:not_processed], admin_cutoff_day_before_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
    # end
  end
end