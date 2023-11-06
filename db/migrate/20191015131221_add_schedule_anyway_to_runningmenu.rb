class AddScheduleAnywayToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :approve_ban_restaurant, :boolean, :default => false
  end
end
