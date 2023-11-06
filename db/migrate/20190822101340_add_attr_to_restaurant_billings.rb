class AddAttrToRestaurantBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :orders_from, :datetime
    add_column :restaurant_billings, :orders_to, :datetime
    add_column :restaurant_billings, :commission, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :restaurant_billings, :food_total, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :restaurant_billings, :sales_tax, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
