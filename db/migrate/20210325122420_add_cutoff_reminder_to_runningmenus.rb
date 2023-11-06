class AddCutoffReminderToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :cutoff_day_before_job_id, :string
    add_column :runningmenus, :cutoff_hour_before_job_id, :string
  end
end
