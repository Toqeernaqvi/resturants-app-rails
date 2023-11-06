class AddPickupIdToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :pickup_task_id, :string, after: :task_id
  end
end
