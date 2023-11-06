json.total_pages @runningmenus.total_pages
json.per_page @per_page
json.sort_by @sort_by
json.sort_order @sort_order
json.runningmenus @runningmenus.each do |runningmenu|
  json.(
    runningmenu, :id, :slug, :runningmenu_name, :delivery_at, :cutoff_at, :admin_cutoff_at
  )
  json.company_name runningmenu.company.name
  json.formatted_address runningmenu.address.formatted_address
  # fooditem_names = runningmenu.orders.active.joins(:fooditem).where(:user_id=>current_member.id).pluck("fooditems.name")
  fooditems = runningmenu.orders.active.joins(:fooditem, :restaurant, :restaurant_address).where(:user_id=>current_member.id).select("restaurants.name AS restaurant_name, addresses.logo, addresses.id AS address_id, fooditems.name AS fooditem_name, (CASE WHEN user_markup THEN user_price+site_price ELSE user_price END) AS user_p").collect{|o| {fooditem_name: o.fooditem_name, restaurant_name: o.restaurant_name, logo: o.logo.nil? ? nil : "https://#{ENV['S3_BUCKET_NAME']}.s3.amazonaws.com/uploads/address/logo/#{o.address_id}/medium_#{o.logo}", user_paid: o.user_p } }
  if fooditems.blank?
    json.restaurants_count runningmenu.addresses.count
    json.your_order [Unordered: runningmenu.addresses.collect{|a| {name: a.addressable.name, logo: a.logo.url(:medium)} }.uniq ]
  else
    json.restaurants_count fooditems.pluck(:restaurant_name).uniq.count
    json.your_order fooditems
  end
  # json.your_cost runningmenu.orders.active.where(:user_id=>current_member.id).collect{|o| o.user_paid}.sum
  json.group runningmenu.orders.active.where(:user_id=>current_member.id).collect{|o| o.group_view}.compact.uniq.join(", ")
end