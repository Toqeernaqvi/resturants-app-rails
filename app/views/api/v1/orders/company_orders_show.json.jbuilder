# if @orders.present?
#   json.set! 'order_summary' do
#     json.meeting_name @orders.first.runningmenu.runningmenu_name
#     json.meeting_type @orders.first.runningmenu.runningmenu_type
#     json.meeting_style @orders.first.runningmenu.menu_type
#     json.total_quantity @orders.sum(:quantity).to_i
#     json.ordered_at @orders.first.runningmenu.delivery_at_timezone
#     json.address @orders.first.runningmenu.address
#     json.total_price @orders.map{|order| order.total_price}.sum
#   end

#   json.set! 'orders' do
#     json.array! @orders.active do |order|
#       json.id order.id
#       json.restaurant_name order.restaurant.name
#       json.cutoff_at order.runningmenu.cutoff_at_timezone
#       json.admin_cutoff_at order.runningmenu.admin_cutoff_at_timezone
#       json.user do
#         json.id order.user.id
#         json.name order.user.name
#         json.email order.user.email
#       end
#       json.fooditem order.fooditem
#       json.set! 'options' do
#         order.optionsets_orders.each do |optionset_order|
#           json.array! optionset_order.options_orders do |option_order|
#             json.description option_order.option.description
#           end
#         end
#       end
#       json.quantity order.quantity
#       json.price order.total_price
#       json.user_price order.user_price
#       json.company_price order.company_price
#       json.site_price order.site_price
#     end
#   end
# end
# json.set! 'no_order_users' do
#   json.array! @users do |user|
#     json.id user.id
#     json.first_name user.first_name
#     json.last_name user.last_name
#     json.email user.email
#   end
# end
