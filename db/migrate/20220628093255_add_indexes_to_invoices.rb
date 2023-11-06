class AddIndexesToInvoices < ActiveRecord::Migration[5.1]
  def change
    add_index :invoices, :invoice_number
    add_index :invoices, :company_id

    add_index :orders, :invoice_id
    add_index :orders, [:invoice_id, :status]
  end
end
