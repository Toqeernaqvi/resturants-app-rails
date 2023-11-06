class ChangeDecimalPlacesToOrders < ActiveRecord::Migration[5.1]
  def self.up
    change_column :orders, :sales_tax, :decimal, :precision => 12, :scale => 6, default: 0.00
    change_column :orders, :restaurant_commission, :decimal, :precision => 12, :scale => 6, default: 0.00
    change_column :orders, :restaurant_payout, :decimal, :precision => 12, :scale => 6, default: 0.00
  end
  def self.down
    change_column :orders, :sales_tax, :decimal, :precision => 8, :scale => 2, default: 0.00
    change_column :orders, :restaurant_commission, :decimal, :precision => 8, :scale => 2, default: 0.00
    change_column :orders, :restaurant_payout, :decimal, :precision => 8, :scale => 2, default: 0.00
  end
end
