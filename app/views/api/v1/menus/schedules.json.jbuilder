# json.default @schedule
# json.first_pending_delivery @first_pending_delivery&.in_time_zone(current_member.company.time_zone)
json.share_meeting @share_meeting
# ['breakfast', 'lunch', 'dinner'].each do |runningmenu_type|
#   json.set! runningmenu_type do
#     json.array! @schedules.each do |schedule|
#       if schedule.runningmenu_type == runningmenu_type
#         json.(
#           schedule, :id, :runningmenu_type, :address_id, :delivery_at, :date, :year, :month, :day
#         )
#         json.ordered_quantity schedule.orders.active.sum(:quantity)
#       end
#     end
#   end
# end
#
# json.set! 'booked' do
#   ['breakfast', 'lunch', 'dinner'].each do |runningmenu_type|
#     json.set! runningmenu_type do
#       json.array! @booked.each do |booked|
#         if booked.runningmenu.runningmenu_type == runningmenu_type
#           json.(
#             booked, :address_id, :delivery_at, :date, :year, :month, :day
#           )
#         end
#       end
#     end
#   end
# end

json.dietaries do
  json.array! Dietary.active.all do |dietary|
    json.(
      dietary,
      :id, :name
    )
  end
end

json.ingredients do
  json.array! Ingredient.active.all do |ingredient|
    json.(
      ingredient,
      :id, :name
    )
  end
end

# json.addresses do
#   json.array! @company.addresses.active do |address|
#     json.address address
#   end
# end

# json.company current_member.company
#
# json.custom_fields do
#   json.array! current_member.company.fields.active do |field|
#     json.id field.id
#     json.field_type field.field_type
#     json.name field.name
#     json.required field.required
#     #requestfield = Runningmenurequestfield.find_by(runningmenu_id: @schedule.id, field_id: field.id)
#
#     # value = (requestfield.present?) ? requestfield.value : ''
#     # id = (requestfield.present?) ? requestfield.id : ''
#     # json.runningmenu_id id
#     # json.value value
#
#     if field.field_type == 'dropdown'
#       json.options do
#         json.array! field.fieldoptions.active do |fieldoption|
#           json.id fieldoption.id
#           json.name fieldoption.name
#           #json.selected Runningmenurequestfield.exists?(runningmenu_id: @schedule.id, field_id: field.id, fieldoption_id: fieldoption.id)
#         end
#       end
#     end
#   end
# end
