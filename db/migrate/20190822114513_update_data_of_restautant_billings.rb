class UpdateDataOfRestautantBillings < ActiveRecord::Migration[5.1]
  def change
    RestaurantBilling.all.each do |restaurant_billing|
      sorted_orders = restaurant_billing.orders.active.joins(:runningmenu).where(runningmenus: {status: Runningmenu.statuses[:approved]}).order("runningmenus.delivery_at ASC")
      restaurant_billing.orders_from = sorted_orders.pluck(:delivery_at).first.in_time_zone("Pacific Time (US & Canada)")
      restaurant_billing.orders_to = sorted_orders.pluck(:delivery_at).last.in_time_zone("Pacific Time (US & Canada)")
      restaurant_billing.food_total = (sprintf "%.2f", restaurant_billing.orders.active.sum(:food_price_total)).to_f
      restaurant_billing.commission = (sprintf "%.2f", ((restaurant_billing.food_total * restaurant_billing.address.discount_percentage)/100) ).to_f
      restaurant_billing.sales_tax = (sprintf "%.2f", ((restaurant_billing.food_total * 9.25)/100)).to_f
      restaurant_billing.due_date = restaurant_billing.address.delayed_payout_days.days.since( restaurant_billing.orders.joins(:runningmenu).order("runningmenus.delivery_at desc").pluck("runningmenus.delivery_at").first )
      restaurant_billing.save
    end
  end
end
