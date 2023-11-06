class AddRefundToPaymentLogs < ActiveRecord::Migration[5.1]
  
  def change
    add_column :payment_logs, :transaction_id, :string
    add_column :payment_logs, :refund_amount, :decimal, :precision => 8, :scale => 2, default: 0
    add_column :payment_logs, :refund_date, :datetime 
    add_column :payment_logs, :refund_by, :integer 
  end

end
