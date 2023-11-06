class AddFinalStatusJobIdToRestaurantBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :final_status_job_id, :string
  end
end
