class AddJobsStatusesToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :notify_restaurant_job_status, :integer, default: 0
    add_column :runningmenus, :cutoff_reached_job_status, :integer, default: 0
    add_column :runningmenus, :admin_cutoff_reached_job_status, :integer, default: 0
    add_column :runningmenus, :buffet_delivery_reminder_job_status, :integer, default: 0
    add_column :runningmenus, :cutoff_day_before_job_status, :integer, default: 0
    add_column :runningmenus, :cutoff_hour_before_job_status, :integer, default: 0
    add_column :runningmenus, :restaurant_billing_job_status, :integer, default: 0
    add_column :runningmenus, :survey_job_status, :integer, default: 0
    add_column :runningmenus, :fleet_create_task_job_status, :integer, default: 0
    add_column :runningmenus, :fleet_update_task_job_status, :integer, default: 0
    add_column :runningmenus, :user_pending_amount_job_status, :integer, default: 0

    add_column :runningmenus, :notify_restaurant_job_error, :string
    add_column :runningmenus, :cutoff_reached_job_error, :string
    add_column :runningmenus, :admin_cutoff_reached_job_error, :string
    add_column :runningmenus, :buffet_delivery_reminder_job_error, :string
    add_column :runningmenus, :cutoff_day_before_job_error, :string
    add_column :runningmenus, :cutoff_hour_before_job_error, :string
    add_column :runningmenus, :restaurant_billing_job_error, :string
    add_column :runningmenus, :survey_job_error, :string
    add_column :runningmenus, :fleet_create_task_job_error, :string
    add_column :runningmenus, :fleet_update_task_job_error, :string
    add_column :runningmenus, :user_pending_amount_job_error, :string
  end
end
