class RedoBillingNumbers < ActiveRecord::Migration[5.1]
  def change
    billing_number = 20000
    RestaurantBilling.all.each do |rest_bill|
      rest_bill.update_column(:billing_number, billing_number)
      billing_number += 1
    end
  end
end
