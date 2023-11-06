# json.set! 'orders' do
#   json.array! @orders do |order|
#     json.runningmenu_id order.runningmenu_id
#     json.address order.runningmenu.address
#     json.runningmenu_name order.runningmenu.runningmenu_name
#     json.restaurant_name order.restaurant.name
#     json.location order.runningmenu.address.location
#     json.order_status order.status
#     json.order_type order.runningmenu.runningmenu_type
#     json.ordered_at order.runningmenu.delivery_at_timezone
#     json.total_quantity order.total_quantity.to_i
#     json.total_price order.total_price
#     json.delivery_instructions order.delivery_instructions
#   end
# end
