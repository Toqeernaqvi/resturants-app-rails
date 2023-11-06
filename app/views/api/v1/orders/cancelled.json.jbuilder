json.set! 'orders' do
  json.array! current_member.orders.cancelled.order(id: :desc) do |order|
    json.id order.id
    json.restaurant order.restaurant.name rescue ''

    json.cutoff_at order.runningmenu.cutoff_at_timezone
    json.admin_cutoff_at order.runningmenu.admin_cutoff_at_timezone

    json.order_type order.runningmenu.runningmenu_type
    json.rated order.rating > 0
    json.address order.runningmenu.address
    json.date order.runningmenu.delivery_at_timezone
    json.quantity order.quantity
    json.fooditem order.fooditem
  end
end
