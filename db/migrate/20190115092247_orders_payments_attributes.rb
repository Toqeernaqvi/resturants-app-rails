class OrdersPaymentsAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :pending_total, :decimal, default: 0, :precision => 8, :scale => 2, after: :first_time
    add_column :orders, :payment_status, :integer, default: 0, after: :status
  end
end
