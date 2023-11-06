class OrdersUsers < ActiveRecord::Migration[5.1]
  def change
  	add_reference :orders, :user, index: true, foreign_key: true, after: :id
    add_column :orders, :status, :integer, default: 0, after: :total_price
  end
end
