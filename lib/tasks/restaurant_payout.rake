# namespace :restaurant_payout do
#   desc "Task to generate Restaurant Payout"
#   task generate: :environment do
#     RestaurantBilling.generate
#   end

#   desc "Task to set final status of Restaurant Payout"
#   task set_final_status: :environment do
#     RestaurantBilling.set_final_status()
#   end

#   desc "Task to set due status of Restaurant Billing"
#   task set_status_to_due: :environment do
#     RestaurantBilling.set_status_to_due()
#   end

#   desc "Task to pay Restaurant Admin"
#   task pay: :environment do
#     RestaurantBilling.pay_to_restaurants()
#   end

# end