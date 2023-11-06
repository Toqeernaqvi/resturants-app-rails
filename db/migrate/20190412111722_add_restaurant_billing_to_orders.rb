class AddRestaurantBillingToOrders < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :restaurant_billing, index: true
  end
end
