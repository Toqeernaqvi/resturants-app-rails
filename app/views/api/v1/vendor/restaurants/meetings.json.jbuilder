json.runningmenus @runningmenus.each do |runningmenu|
  json.(
    runningmenu, :id, :slug, :runningmenu_type, :menu_type
  )
  json.delivery_type runningmenu.delivery_type
  json.delivery_at runningmenu.delivery_at_timezone
  # json.pick_up_time runningmenu.pickup_time(params[:id])
  json.pick_up_time runningmenu.pickup_at_timezone
  json.company do
    json.id runningmenu.company.id
    json.name runningmenu.company.name
    json.address_line runningmenu.address.address_line
  end
  json.user do
    json.id runningmenu.user.id
    json.first_name runningmenu.user.first_name
    json.last_name runningmenu.user.last_name
    json.email runningmenu.user.email
    json.phone_number runningmenu.user.phone_number
  end
  json.items_count runningmenu.orders.active.where(restaurant_address_id: params[:id]).sum(:quantity).to_i
  if runningmenu.driver.present?
    json.driver do
      json.id runningmenu.driver.id
      json.first_name runningmenu.driver.first_name
      json.last_name runningmenu.driver.last_name
    end
  else
    json.driver nil
  end
  restaurant_address = AddressesRunningmenu.find_by(runningmenu_id: runningmenu.id, address_id: params[:id])
  if restaurant_address.rejected_by_vendor
    json.status 'Rejected by vendor'
  elsif restaurant_address.receipt_acknowledge? || restaurant_address.orders_acknowledge? || restaurant_address.changes_acknowledge?
    json.status 'Confirmed'
  else
    json.status 'Unconfirmed'
  end
end