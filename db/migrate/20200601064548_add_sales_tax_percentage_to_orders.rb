class AddSalesTaxPercentageToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :sales_tax_rate, :decimal, precision: 8, scale: 4, default: 0.0000
  end
end
