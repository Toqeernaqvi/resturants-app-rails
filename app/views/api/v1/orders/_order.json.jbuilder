json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid)
json.cutoff_at order.runningmenu.cutoff_at
json.admin_cutoff_at order.runningmenu.admin_cutoff_at
json.guest order.guest
json.custom_fields do
  json.array! order.runningmenu.runningmenufields.joins(:field).order('fields.position ASC') do |orderfield|
    if orderfield.field.present?
      json.orderfields_id orderfield.id
      json.id orderfield.field.id
      json.field_type orderfield.field_type
      json.name orderfield.field.name
      json.required orderfield.field.required
      json.value orderfield.value

      if orderfield.field_type == 'dropdown'
        json.options do
          json.array! orderfield.field.fieldoptions do |fieldoption|
            json.id fieldoption.id
            json.name fieldoption.name
            json.selected fieldoption.id == orderfield.fieldoption_id
          end
        end
      end
    end
  end
end
json.fooditem do 
  json.partial! "api/v1/orders/fooditem", fooditem: order.fooditem, order: order
end