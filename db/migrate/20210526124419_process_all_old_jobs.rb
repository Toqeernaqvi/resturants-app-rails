class ProcessAllOldJobs < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where('delivery_at < ?', Time.current).update_all(
      notify_restaurant_job_status: Runningmenu.notify_restaurant_job_statuses[:processed], cutoff_reached_job_status: Runningmenu.cutoff_reached_job_statuses[:processed],
      admin_cutoff_reached_job_status: Runningmenu.admin_cutoff_reached_job_statuses[:processed], buffet_delivery_reminder_job_status: Runningmenu.buffet_delivery_reminder_job_statuses[:processed],
      cutoff_day_before_job_status: Runningmenu.cutoff_day_before_job_statuses[:processed], cutoff_hour_before_job_status: Runningmenu.cutoff_hour_before_job_statuses[:processed],
      restaurant_billing_job_status: Runningmenu.restaurant_billing_job_statuses[:processed], survey_job_status: Runningmenu.survey_job_statuses[:processed],
      fleet_create_task_job_status: Runningmenu.fleet_create_task_job_statuses[:processed], fleet_update_task_job_status: Runningmenu.fleet_update_task_job_statuses[:processed],
      user_pending_amount_job_status: Runningmenu.user_pending_amount_job_statuses[:processed]
    )
  end
end
