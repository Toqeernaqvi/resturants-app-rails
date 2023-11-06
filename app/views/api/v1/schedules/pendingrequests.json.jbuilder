# ['breakfast', 'lunch', 'dinner'].each do |runningmenu_type|
#   json.set! runningmenu_type do
#     json.array! @runningmenus.each do |schedule|
#       if schedule.runningmenu_type == runningmenu_type
#         json.(
#           schedule, :id, :runningmenu_type, :address_id, :date, :year, :month, :day
#         )
#         json.delivery_at schedule.delivery_at_timezone
#       end
#     end
#   end
# end
