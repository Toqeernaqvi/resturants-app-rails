class CutoffHourBeforeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cutoff_hour_before_reminder

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Cutoff Hour Before Reminder Job for runningmenu_id: #{runningmenu.id}"
        # users = CompanyUser.active.where(company_id: runningmenu.company_id, address_id: runningmenu.address_id).where("cutoff_hour_#{runningmenu.runningmenu_type}_reminder = ?", true).where.not(id: Order.active.where(runningmenu_id: runningmenu.id).pluck('user_id').uniq)
        users = CompanyUser.active.joins("LEFT JOIN orders ON users.id = orders.user_id AND orders.status = #{Order.statuses[:active]} AND orders.runningmenu_id = #{runningmenu.id}").where("orders.user_id IS NULL AND users.company_id = ? AND users.address_id = ? AND users.cutoff_hour_#{runningmenu.runningmenu_type}_reminder = ?", runningmenu.company_id, runningmenu.address_id, true).uniq
        users.each do |user|
          email = OrderMailer.no_order_placed_last_chance(user, runningmenu)
          EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
        end
        runningmenu.update_attributes(cutoff_hour_before_job_status: Runningmenu.cutoff_hour_before_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.update_attributes(cutoff_hour_before_job_status: Runningmenu.cutoff_hour_before_job_statuses[:not_processed], cutoff_hour_before_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
    end
  end
  
end