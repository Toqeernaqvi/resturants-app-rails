class AddCutoffJobToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :cutoff_reached_job_id, :string
    add_column :runningmenus, :admin_cutoff_reached_job_id, :string
    add_column :runningmenus, :buffet_delivery_reminder_job_id, :string
  end
end
