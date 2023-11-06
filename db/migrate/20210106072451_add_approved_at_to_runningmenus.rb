class AddApprovedAtToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :approved_at, :timestamp
  end
end
