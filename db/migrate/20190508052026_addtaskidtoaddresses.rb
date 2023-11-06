class Addtaskidtoaddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :id, :primary_key
    add_column :addresses_runningmenus, :restaurant_task_id, :string
  end
end
