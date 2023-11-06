class AddTotalAmountDueQbToInvoices < ActiveRecord::Migration[5.1]
  def change
  	add_column :invoices, :total_amount_due_qb, :decimal, default: 0, precision: 8, scale: 2
  end
end
