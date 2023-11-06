class AddBillingTypeToRestaurantBilling < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurant_billings, :billing_type, :integer, default: 0
  end
end
