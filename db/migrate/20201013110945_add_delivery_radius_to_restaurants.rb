class AddDeliveryRadiusToRestaurants < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :enable_self_service, :boolean, default: false
    add_column :addresses, :delivery_radius, :integer, default: 20
    add_column :addresses, :delivery_cost, :decimal, precision: 8, scale: 2, default: 0.00
    add_column :addresses, :minimum_order_quantity, :integer, default: 1
  end
end
