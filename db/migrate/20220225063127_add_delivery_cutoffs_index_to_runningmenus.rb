class AddDeliveryCutoffsIndexToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_index :runningmenus, :delivery_at
    add_index :runningmenus, :cutoff_at
    add_index :runningmenus, :admin_cutoff_at
    add_index :runningmenus, :status
    add_index :runningmenus, :user_id
  end
end
