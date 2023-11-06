# json.schedules @runningmenus do |schedule|
#   if schedule.runningmenu_request.present?
#     json.id schedule.id
#     json.scheduler_request_id schedule.runningmenu_request.id
#     json.user schedule.runningmenu_request.user.name
#     json.email schedule.runningmenu_request.user.email
#     json.orders schedule.runningmenu_request.orders
#     json.type schedule.runningmenu_request.runningmenu_request_type
#     json.delivery_at schedule.delivery_at_timezone.to_date
#     json.end_time schedule.runningmenu_request.end_time
#     json.address schedule.runningmenu_request.address.name
#     json.special_request schedule.runningmenu_request.special_request
#     json.menu_type schedule.runningmenu_request.menu_type
#     json.delivery_instructions schedule.delivery_instructions
#     json.status schedule.status

#     json.selected_cuisines schedule.runningmenu_request.cuisines_requests do |cuisine_request|
#       json.id cuisine_request.id
#       json.value cuisine_request.cuisine.id
#       json.label cuisine_request.cuisine.name
#     end

#     json.custom_fields do
#       json.array! current_member.company.fields.order(position: :asc) do |field|
#         json.id field.id
#         json.field_type field.field_type
#         json.name field.name
#         json.required field.required
#         requestfield = Runningmenurequestfield.find_by(runningmenu_request_id: schedule.runningmenu_request.id, field_id: field.id)

#         value = (requestfield.present?) ? requestfield.value : ''
#         id = (requestfield.present?) ? requestfield.id : ''
#         json.runningmenu_request_id id
#         json.value value

#         if field.field_type == 'dropdown'
#           json.options do
#             json.array! field.fieldoptions.order(position: :asc) do |fieldoption|
#               json.id fieldoption.id
#               json.name fieldoption.name
#               json.selected Runningmenurequestfield.exists?(runningmenu_request_id: schedule.runningmenu_request.id, field_id: field.id, fieldoption_id: fieldoption.id)
#             end
#           end
#         end
#       end
#     end
#   end
# end

# json.custom_fields do
#   json.array! current_member.company.fields.order(position: :asc) do |field|
#     json.id field.id
#     json.field_type field.field_type
#     json.name field.name
#     json.required field.required
#     if field.field_type == 'dropdown'
#       json.options do
#         json.array! field.fieldoptions do |fieldoption|
#           json.id fieldoption.id
#           json.name fieldoption.name
#         end
#       end
#     end
#   end
# end
