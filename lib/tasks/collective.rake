namespace :collective do
  
  desc "Tasks to execute collectively"
  task ten_minutes: :environment do
    # 'foodfeedback:orderfeedback' "Task for Feedback of Order"
    # begin
    #   puts "Task for Feedback of Order start"
    #   Order.survey()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task for Feedback of Order error"
    # end
    # 'cutoffreminder:cutoff_reminder' "Task for Reminder of Order"
    # begin
    #   puts "Task for Reminder of Order start"
    #   Order.cutoff_reminder()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task for Reminder of Order error"
    # end
    # 'restaurant_payout:generate' "Task to generate Restaurant Payout"
    # begin
    #   puts "Task to generate Restaurant Payout start"
    #   RestaurantBilling.generate
    # rescue Exception => e
    #   puts e.message
    #   puts "Task to generate Restaurant Payout error"
    # end
    # 'onfleet_tasks:onfleet_task' "Task add to onfleet"
    # begin
    #   puts "Task add to onfleet start"
    #   Runningmenu.fleet_create_task()
    #   Runningmenu.fleet_update_task()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task add to onfleet error"
    # end
  end

  desc "Tasks to execute collectively"
  task hourly: :environment do
    # 'pendingtotalcalculate:pending_total' "Task for Calculate of pending total of user"
    # begin
    #   puts "Task for Calculate of pending total of user start"
    #   User.calculate_pendingtotal()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task for Calculate of pending total of user error"
    # end
    # 'ordertransaction:orderpayment' "Task for Payment of Orders"
    # begin
    #   puts "Task for Payment of Orders start"
    #   Order.orderprocessing()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task for Payment of Orders error"
    # end
    # 'restaurant_payout:set_final_status' "Task to set final status of Restaurant Payout"
    # begin
    #   puts "Task to set final status of Restaurant Payout start"
    #   RestaurantBilling.set_final_status()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task to set final status of Restaurant Payout error"
    # end
    # 'restaurant_payout:set_status_to_due' "Task to set due status of Restaurant Billing"
    # begin
    #   puts "Task to set due status of Restaurant Billing start"
    #   RestaurantBilling.set_status_to_due()
    # rescue Exception => e
    #   puts e.message
    #   puts "Task to set due status of Restaurant Billing error"
    # end
    # 'recurring:schedulers' "Task to generate schedulers based on recurrence template"
    begin
      puts "Task to send message 4pm day before delivery start"
      Runningmenu.four_pm_day_before_delivery
      Runningmenu.seven_am_day_of_delivery
    rescue Exception => e
      puts e.message
      puts "Task to send message 4pm day before delivery failed"
    end
    #task to send upcoming orders to restaurants daily at seven pm
    begin
      puts "Task to send email 7pm daily"
      Runningmenu.seven_pm_daily
    rescue Exception => e
      puts e.message
      puts "Task to send email 7pm daily failed"
    end
    begin
      puts "Task to generate schedulers based on recurrence template start"
      RecurringScheduler.generate_schedulers
    rescue Exception => e
      puts e.message
      puts "Task to generate schedulers based on recurrence template error"
    end
    'dashboard_metric:highest_rated_restaurants' "Task to udpate highest rated restaurants on dashboard"
    begin
      puts "Task to udpate highest rated restaurants on dashboard start"
      DashboardMetric.highest_rated_restaurants()
    rescue Exception => e
      puts e.message
      puts "Task to udpate highest rated restaurants on dashboard error"
    end
    # 'dashboard_metric:lowest_rated_restaurants' "Task to update lowest rated restaurants on dashboard"
    begin
      puts "Task to update lowest rated restaurants on dashboard start"
      DashboardMetric.lowest_rated_restaurants()
    rescue Exception => e
      puts e.message
      puts "Task to update lowest rated restaurants on dashboard error"
    end
    # 'dashboard_metric:highest_rated_dishes' "Task to udpate highest rated dishes on dashboard"
    begin
      puts "Task to udpate highest rated dishes on dashboard start"
      DashboardMetric.highest_rated_dishes()
    rescue Exception => e
      puts e.message
      puts "Task to udpate highest rated dishes on dashboard error"
    end
    # 'dashboard_metric:lowest_rated_dishes' "Task to udpate lowest rated dishes on dashboard"
    begin
      puts "Task to udpate lowest rated dishes on dashboard start"
      DashboardMetric.lowest_rated_dishes()
    rescue Exception => e
      puts e.message
      puts "Task to udpate lowest rated dishes on dashboard error"
    end
  end

end