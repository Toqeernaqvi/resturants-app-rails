class CreateOrderChangeLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :order_change_logs do |t|
      t.references :order, foreign_key: true
      t.integer :order_quantity

      t.timestamps
    end
  end
end
