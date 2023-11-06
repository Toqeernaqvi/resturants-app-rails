class InitRestaurantBillingJobForFutureDeliveries < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.pickup.where("delivery_at > ?", Time.current).each do |runningmenu|
      runningmenu.set_restaurant_billing_job
    end
  end
end
