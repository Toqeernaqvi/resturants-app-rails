class AddBeforePickupJobToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :before_pickup_job_id, :string
    add_column :addresses_runningmenus, :before_pickup_job_status, :integer, default: 0
    add_column :addresses_runningmenus, :before_pickup_job_error, :string
  end
end
