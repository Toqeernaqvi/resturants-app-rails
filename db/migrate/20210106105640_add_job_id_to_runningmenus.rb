class AddJobIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :job_id, :string
  end
end
