class AddRestaurantPayoutToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :number_of_meals, :integer, default: 0
    add_column :orders, :sales_tax, :decimal, :precision => 8, :scale => 2, default: 0.00
    add_column :orders, :restaurant_commission, :decimal, :precision => 8, :scale => 2, default: 0.00
    add_column :orders, :restaurant_payout, :decimal, :precision => 8, :scale => 2, default: 0.00
  end
end
