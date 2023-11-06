class CreateJoinTableOrdersPaymentLogs < ActiveRecord::Migration[5.1]
  def change
    create_join_table :orders, :payment_logs do |t|
      t.index [:order_id, :payment_log_id]
    end
  end
end
