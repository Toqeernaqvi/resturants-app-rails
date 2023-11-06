class FleetUpdateTaskWorker
  include Sidekiq::Worker
  sidekiq_options queue: :fleet_update_task

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Onfleet update task Job for runningmenu_id: #{runningmenu.id}"
        if runningmenu.orders.active.exists?
          runningmenu.onfleet_update_task
        end
        runningmenu.assign_attributes(fleet_update_task_job_status: Runningmenu.fleet_update_task_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.assign_attributes(fleet_update_task_job_status: Runningmenu.fleet_update_task_job_statuses[:not_processed], fleet_update_task_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end
  
end