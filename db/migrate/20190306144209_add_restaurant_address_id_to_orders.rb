class AddRestaurantAddressIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :restaurant_address_id, :integer, after: :restaurant_id
  end
end
