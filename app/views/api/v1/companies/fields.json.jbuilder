json.custom_fields do
  fields = @share_meeting.present? ? @share_meeting.runningmenu.company.fields.active.order(position: :asc) : current_member.company.fields.active.order(position: :asc)
  json.array! fields do |field|
    json.id field.id
    json.field_type field.field_type
    json.name field.name
    json.required field.required
    if field.field_type == 'dropdown'
      json.options do
        json.array! field.fieldoptions.active do |fieldoption|
          json.id fieldoption.id
          json.name fieldoption.name
        end
      end
    end
  end
end
