class AddPickupAtToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :pickup_at, :timestamptz, after: :admin_cutoff_at
  end
end
