json.set! 'orders' do
  json.array! current_member.orders.active.joins(:runningmenu).order("runningmenus.delivery_at DESC") do |order|
    json.id order.id
    json.user order.user
    json.delivery_at order.runningmenu.delivery_at_timezone
    json.restaurant order.restaurant.name rescue ''

    json.cutoff_at order.runningmenu.cutoff_at_timezone
    json.admin_cutoff_at order.runningmenu.admin_cutoff_at_timezone

    json.order_type order.runningmenu.runningmenu_type
    json.rated order.rating > 0
    json.remarks order.remarks
    json.address order.runningmenu.address
    json.date order.runningmenu.delivery_at_timezone
    json.quantity order.quantity
    if order.fooditem.present?
      json.fooditem order.fooditem
    end
  end
end
