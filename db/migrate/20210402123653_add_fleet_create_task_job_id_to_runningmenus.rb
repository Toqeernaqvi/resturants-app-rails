class AddFleetCreateTaskJobIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :fleet_create_task_job_id, :string
  end
end
