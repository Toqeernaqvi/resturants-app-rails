class SetDueRestaurantBillingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :set_due_restaurant_billing

  def perform(restaurant_billing_id)
    restaurant_billing = RestaurantBilling.find restaurant_billing_id
    puts "Set Due Status RestaurantBilling Job for restaurant_billing_id: #{restaurant_billing.id}"
    restaurant_billing.set_due_status if restaurant_billing.final?
  end
end