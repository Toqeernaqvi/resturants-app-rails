class AddColsToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :task_status, :integer, default: 0
    add_column :runningmenus, :pickup_task_status, :integer, default: 0
    add_column :addresses_runningmenus, :task_status, :integer, default: 0
    add_column :runningmenus, :arriving_at, :integer
  end
end
