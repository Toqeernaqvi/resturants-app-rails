class AddAdminCutoffDayHourBeforeJobsToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :admin_cutoff_day_before_job_id, :string
    add_column :runningmenus, :admin_cutoff_hour_before_job_id, :string
    add_column :runningmenus, :admin_cutoff_day_before_job_status, :integer, default: 0
    add_column :runningmenus, :admin_cutoff_hour_before_job_status, :integer, default: 0
    add_column :runningmenus, :admin_cutoff_day_before_job_error, :string
    add_column :runningmenus, :admin_cutoff_hour_before_job_error, :string
  end
end
