class AddNewFieldsToRestaurantBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :tips, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :restaurant_billings, :credit_card_fees, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :restaurant_billings, :billing_number, :integer
    add_column :restaurant_billings, :payment_method, :integer, default: 0
  end
end
