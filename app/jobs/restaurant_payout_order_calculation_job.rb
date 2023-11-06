class RestaurantPayoutOrderCalculationJob < ApplicationJob
  queue_as :restaurant_payout_order_calculation

  def perform(id)
    orders = Order.active.joins(:runningmenu).where("orders.restaurant_address_id = ? AND runningmenus.status = ? AND runningmenus.delivery_at >= ?", id, Runningmenu.statuses[:approved], Time.current)
    unless orders.blank?
      orders.each do |order|
        order.init_restaurant_payout_calculation
        order.update_columns(number_of_meals: order.number_of_meals, sales_tax_rate: order.sales_tax_rate, sales_tax: order.sales_tax, restaurant_commission: order.restaurant_commission, restaurant_payout: order.restaurant_payout)
      end  
    end
  end
end
