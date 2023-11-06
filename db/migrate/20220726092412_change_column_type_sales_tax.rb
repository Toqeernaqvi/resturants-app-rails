class ChangeColumnTypeSalesTax < ActiveRecord::Migration[5.1]
  def change
    change_column :invoices, :sales_tax, :decimal, :precision => 8, :scale => 2, default: 0.00
  end
end
