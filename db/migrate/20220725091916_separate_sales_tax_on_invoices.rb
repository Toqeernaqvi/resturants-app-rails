class SeparateSalesTaxOnInvoices < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :separate_out_sales_tax_on_invoices, :boolean, default: false
  end
end
