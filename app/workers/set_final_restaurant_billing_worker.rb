class SetFinalRestaurantBillingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :set_final_restaurant_billing

  def perform(restaurant_billing_id)
    restaurant_billing = RestaurantBilling.find restaurant_billing_id
    puts "Set Final Status RestaurantBilling Job for restaurant_billing_id: #{restaurant_billing.id}"
    restaurant_billing.set_final_status
  end
end