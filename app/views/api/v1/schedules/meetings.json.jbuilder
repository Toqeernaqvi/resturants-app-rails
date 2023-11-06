# json.runningmenu @runningmenus.each do |runningmenu|
#   json.(
#     runningmenu, :id, :slug, :runningmenu_name, :runningmenu_type, :menu_type, :address_id, :status, :special_request, :share_token, :per_meal_budget, :remaining_time, :per_user_copay, :per_user_copay_amount, :headcount_served, :marketplace, :delivery_instructions
#   )
#   json.delivery_at runningmenu.delivery_at_timezone
#   json.activation_at runningmenu.activation_at_timezone
#   json.cutoff_at runningmenu.cutoff_at_timezone
#   json.admin_cutoff_at runningmenu.admin_cutoff_at_timezone
#   json.approximate_count runningmenu.orders_count
#   field_required = runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.value = ?', 1, Field.field_types[:text], '')
#   if field_required.present?
#     json.field_required field_required.present?
#   else
#     field_required = runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.fieldoption_id IS NULL', 1, Field.field_types[:dropdown])
#     json.field_required field_required.present?
#   end
#   # if runningmenu.end_time.present?
#   #   json.end_time runningmenu.end_time.strftime "%H:%M"
#   # else
#   #   json.end_time runningmenu.delivery_at.strftime "%H:%M"
#   # end
#   json.end_time runningmenu.delivery_at.strftime "%H:%M"
#   active_orders = runningmenu.orders.active.joins(:runningmenu).where("runningmenus.company_id = ?", current_member.company_id)
#   if current_member.company_user?
#     order_count = active_orders.where(user_id: current_member.id).count
#     total_quantity = active_orders.where(user_id: current_member.id).sum(:quantity).to_i
#   else
#     order_count = active_orders.count
#     total_quantity = active_orders.sum(:quantity).to_i
#   end
#   if current_member.company_user?
#     #user_total_price = active_orders.where(user_id: current_member.id).sum(:total_price)
#     json.remaining_budget runningmenu.user_remaining_budget(current_member.id, nil, nil) #.per_meal_budget - user_total_price
#   end
#   json.price_per_head runningmenu.orders_count > 0 ? (active_orders.sum(:total_price) / runningmenu.orders_count) : 0
#   json.order_count order_count
#   json.total_quantity total_quantity
#   json.order_total active_orders.sum(:total_price)
#   total_orders = active_orders.where.not(restaurant_address_id: Restaurant.find_by(name: ENV['BEV_AND_MORE']).addresses.active.first.id)
#   total_order_price = total_orders.sum(:total_price)
#   total_order_quantity = total_orders.sum(:quantity).to_i
#   json.avg_per_meal total_order_price / total_order_quantity
#   json.address_line runningmenu.delivery_room_value
#   json.contact_card runningmenu.contact_card
#   beverages_rest_id = Restaurant.find_by_name(ENV['BEV_AND_MORE']).id
#   if (runningmenu.task_id.present? && !["created", "not_created"].include?(runningmenu.task_status)) ||
#     runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: [:not_created, :created]).uniq.present? ||
#     runningmenu.addresses_runningmenus.joins(:address, :runningmenu).where('addressable_id = ? AND runningmenus.pickup_task_status NOT IN (?)', beverages_rest_id, [Runningmenu.pickup_task_statuses[:created], Runningmenu.pickup_task_statuses[:not_created]]).uniq.present?
#     json.addresses runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: :not_created).order(task_status: :desc).uniq.each do |address_runningmenu|
#       json.restaurant address_runningmenu.address.addressable.name
#       json.task_status address_runningmenu.task_status
#       if Runningmenu.task_statuses.keys[2..3].include?(address_runningmenu.task_status)
#         @driver = @driver_on_way = true
#       end
#     end
#     beverages_rest = runningmenu.addresses_runningmenus.joins(:address, :runningmenu).where('addressable_id = ? AND runningmenus.pickup_task_status NOT IN (?)', beverages_rest_id, [Runningmenu.pickup_task_statuses[:created], Runningmenu.pickup_task_statuses[:not_created]]).order(task_status: :desc).uniq
#     if beverages_rest.any?
#       json.beverages_task ENV['BEV_AND_MORE']
#       json.beverages_task_status runningmenu.pickup_task_status
#       if Runningmenu.task_statuses.keys[2..3].include?(runningmenu.pickup_task_status)
#         @driver = @driver_on_way = true
#       end
#     end
#     json.destination do
#       json.name runningmenu.company.name
#       json.task_status runningmenu.task_status
#       json.arriving_at runningmenu.arriving_at
#       json.completion_time runningmenu.completion_time
#     end
#     if Runningmenu.task_statuses.keys[2..3].include?(runningmenu.task_status)
#       @driver = @driver_on_way = true
#     end
#     if (@driver && !runningmenu.driver.present? && runningmenu.task_id.present?) || (runningmenu.task_status_completed? && !runningmenu.driver.present?)
#       task = Onfleet::Task.get(runningmenu.task_id)
#       driver = task.present? && task.worker.present? ? Onfleet::Worker.get(task.worker) : nil
#       if driver.present?
#         json.driver do
#           json.name driver.name
#           json.ph_number '1-' + number_to_phone(driver.phone.gsub('+1', ''))
#           json.car driver.vehicle.description
#           json.car_color driver.vehicle.color
#           json.car_license_plate driver.vehicle.license_plate
#           json.driver_image nil
#         end
#       else
#         json.driver nil
#       end
#     else
#       json.driver runningmenu.driver
#     end
#     json.driver_on_way @driver_on_way ? @driver_on_way : false
#   end
#   order_ids = []
#   json.ordered_items do
#     json.array! runningmenu.addresses.active.group_by{ |a| a.addressable }.each do |restaurant, addresses|
#       order_counter = 0
#       meeting = Runningmenu.joins(:orders, :addresses).where.not(:id=>runningmenu.id).where(runningmenus: {company_id: runningmenu.company_id, runningmenu_type: runningmenu.runningmenu_type, menu_type: runningmenu.menu_type}, addresses: { id: addresses.pluck(:id)}, orders: { status: :active}).where("runningmenus.delivery_at < ?", Time.current).order(delivery_at: :asc).last
#       if meeting.present?
#         meeting.orders.active.joins(:fooditem).where(orders: {restaurant_address_id: addresses.pluck(:id)}, fooditems: {status: "active"}).each do |order|
#           if order.optionsets_orders.blank?
#             order_ids << order.id
#             order_counter = order_counter + 1
#           else
#             if order.optionsets.where(:status=>"deleted").blank? && order.optionsets_orders.joins(:options_orders=>:option).where(options_orders: {options: {status: "deleted"}}).blank?
#               order_ids << order.id
#               order_counter = order_counter + 1
#             end
#           end
#         end
#       end
#       next if order_counter < 1
#       json.restaurant restaurant.name
#       json.count order_counter
#     end
#   end
#   json.order_ids order_ids.flatten.uniq
# end
# json.meetings_at_your_location @runningmenus.select{|meeting| meeting.address_id == current_member.address_id }.size
# json.meetings_at_nearby_location @runningmenus.select{|meeting| meeting.address_id != current_member.address_id }.size