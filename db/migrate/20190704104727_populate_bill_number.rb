class PopulateBillNumber < ActiveRecord::Migration[5.1]
  def change
    RestaurantBilling.all.each do|r|
      bill_num = RestaurantBilling.select('MAX(billing_number) AS billing_number').last.billing_number
    	r.billing_number = bill_num.blank? ? 10001 : bill_num+1
      r.save
    end
  end
end
