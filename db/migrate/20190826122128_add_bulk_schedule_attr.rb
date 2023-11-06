class AddBulkScheduleAttr < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :notify_admin, :boolean
    add_column :runningmenus, :csv_imported, :boolean
  end
end
