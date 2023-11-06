# json.total_pages @runningmenus.total_pages
# json.per_page @per_page
json.sort_by @sort_by
json.sort_order @sort_order
json.runningmenus @runningmenus.each do |runningmenu|
  json.(
    runningmenu, :id, :slug, :runningmenu_name, :delivery_at, :cutoff_at, :admin_cutoff_at, :orders_count, :per_meal_budget
  )
  json.company_name runningmenu.company.name
  json.formatted_address runningmenu.address.formatted_address
end