class AddToBePaidAtToRestaurantBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :to_be_paid_at, :date
  end
end
