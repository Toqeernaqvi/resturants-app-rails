class CreatePaymentLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :payment_logs do |t|
      t.references :user
      t.decimal :amount, :precision => 8, :scale => 2, default: 0
      t.integer :payment_gateway
      t.integer :status
      t.text :message
      t.timestamps
    end
  end
end
