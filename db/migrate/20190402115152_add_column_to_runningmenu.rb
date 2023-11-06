class AddColumnToRunningmenu < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :end_time, :time
  end
end
