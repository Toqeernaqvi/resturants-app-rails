namespace :restaurant_alert do
  desc "Task add to alert restaurant"
  task restaurant_alert: :environment do
    Runningmenu.restaurant_alert()
  end
end
