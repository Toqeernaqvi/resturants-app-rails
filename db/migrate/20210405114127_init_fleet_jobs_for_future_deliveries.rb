class InitFleetJobsForFutureDeliveries < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where("delivery_at > ? AND (cutoff_at > ? OR admin_cutoff_at > ?)", Time.current, Time.current, Time.current).each do |runningmenu|
      if runningmenu.orders.active.exists?
        runningmenu.onfleet_create_task if runningmenu.cutoff_at > Time.current && runningmenu.fleet_create_task_job_id.blank?
        runningmenu.onfleet_update_task if runningmenu.admin_cutoff_at > Time.current && runningmenu.fleet_update_task_job_id.blank?
      end
    end
  end
end
