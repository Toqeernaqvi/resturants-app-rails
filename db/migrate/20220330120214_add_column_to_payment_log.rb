class AddColumnToPaymentLog < ActiveRecord::Migration[5.1]
  def change
    add_column :payment_logs, :sales_receipt, :boolean, default: false
  end
end
