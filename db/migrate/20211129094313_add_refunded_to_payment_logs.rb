class AddRefundedToPaymentLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :payment_logs, :refunded_amount, :decimal, :precision => 8, :scale => 2, default: 0
  end
end
