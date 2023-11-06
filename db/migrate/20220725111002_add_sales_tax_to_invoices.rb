class AddSalesTaxToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :invoices, :sales_tax, :decimal, :precision => 12, :scale => 6, default: 0.00
  end
end
