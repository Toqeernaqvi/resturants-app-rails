class AddTotalToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :quantity_total, :bigint, default: 0
    add_column :restaurant_billings, :payout_total, :decimal, precision: 8, scale: 2, default: 0.0
  end
end
