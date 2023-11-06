class AddColumnsToRunningmenuRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenu_requests, :end_time, :time, after: :delivery_at
  end
end
