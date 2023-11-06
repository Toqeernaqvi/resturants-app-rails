class AddAmountDuesToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :invoices, :total_amount, :decimal, default: 0, precision: 8, scale: 2
    add_column :invoices, :total_discount, :decimal, default: 0, precision: 8, scale: 2
    add_column :invoices, :total_amount_due, :decimal, default: 0, precision: 8, scale: 2
  end
end
