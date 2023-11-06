class AddRestaurantBillingJobIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :restaurant_billing_job_id, :string
  end
end
