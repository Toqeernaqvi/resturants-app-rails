json.restaurant_name @restaurant.name
json.cuisines @restaurant.cuisines do |cuisine|
  json.id cuisine.id
  json.name cuisine.name
end

json.addresses @restaurants.each do |restaurant|
  json.address_line restaurant.address_line
  json.id restaurant.id
  json.name restaurant.adress_name_format
  json.enable_self_service restaurant.enable_self_service
  json.order_presence Order.active.where(created_at: current_member.last_sign_in_at..current_member.current_sign_in_at, restaurant_address_id: restaurant.id).exists?
  json.billing_tab restaurant.addressable.restaurant_billings.count > 0

end
