class MeetingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :meetings_queue

  def perform(id)
    puts "Sending After 30 minutes email for runningmenu_id: #{id}"
    runningmenu = Runningmenu.approved.find_by_id id
    if runningmenu.present?
      begin
        runningmenu.notify_restaurant_contacts
        runningmenu.assign_attributes(notify_restaurant_job_status: Runningmenu.notify_restaurant_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
        runningmenu.save(validate: false)
      rescue StandardError => e
        runningmenu.assign_attributes(notify_restaurant_job_status: Runningmenu.notify_restaurant_job_statuses[:not_processed], notify_restaurant_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
        runningmenu.save(validate: false)
      end
    end

  end

end