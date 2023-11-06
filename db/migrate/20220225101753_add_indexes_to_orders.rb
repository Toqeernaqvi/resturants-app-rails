class AddIndexesToOrders < ActiveRecord::Migration[5.1]
  def change
    add_index :orders, :restaurant_address_id
    add_index :orders, :created_at
    add_index :orders, :updated_at
  end
end
