class PopulateAdjustments < ActiveRecord::Migration[5.1]
  def self.up
    Adjustment.update_all("adjustable_type='RestaurantBilling',adjustable_id=restaurant_billing_id")
  end

  def self.down
  end
end
