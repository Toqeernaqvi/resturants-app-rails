class AddFleetUpdateTaskJobIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :fleet_update_task_job_id, :string
  end
end
