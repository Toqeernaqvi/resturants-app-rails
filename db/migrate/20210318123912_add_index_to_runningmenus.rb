class AddIndexToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_index :runningmenus, [:deleted_at, :status, :menu_type, :delivery_at, :cutoff_at], name: 'buffet_delivery_reminder_index'
    add_index :runningmenus, [:deleted_at, :status, :cutoff_at], name: 'cutoffreached_reminder_index'
    add_index :runningmenus, [:deleted_at, :status, :admin_cutoff_at], name: 'admincutoffreached_reminder_index'
  end
end
