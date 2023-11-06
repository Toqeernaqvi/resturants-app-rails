class AddFoodPriceToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :food_price, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :orders, :food_price_total, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
