class ChangeDefaultValueForInvoiceStatus < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:invoices, :status, 0)
  end
end
