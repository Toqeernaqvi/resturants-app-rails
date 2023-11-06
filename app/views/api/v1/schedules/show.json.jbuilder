json.schedule do
  json.id @runningmenu.id
  json.slug @runningmenu.slug
  json.runningmenu_type @runningmenu.runningmenu_type
  json.address_id @runningmenu.address_id
  json.delivery_at @runningmenu.delivery_at_timezone
  json.activation_at @runningmenu.activation_at_timezone
  json.cutoff_at @runningmenu.cutoff_at_timezone
  json.admin_cutoff_at @runningmenu.admin_cutoff_at_timezone
  json.menu_type @runningmenu.menu_type
  json.orders_count @runningmenu.orders_count
  json.marketplace @runningmenu.marketplace
  json.status @runningmenu.status
  json.special_request @runningmenu.special_request
  json.end_time @runningmenu.end_time
  json.pop_end_time @runningmenu.end_time&.strftime "%H:%M"
  json.runningmenu_name @runningmenu.runningmenu_name
  json.per_meal_budget @runningmenu.per_meal_budget
  json.formatted_address @runningmenu.address.formatted_address
  json.remaining_time @runningmenu.remaining_time
  json.total_quantity @runningmenu.total_quantity
  json.delivery_instructions @runningmenu.delivery_instructions
  order_total = @runningmenu.orders.active.sum(:total_price)
  json.order_total order_total-@runningmenu.orders.active.sum(:user_paid)
  json.avg_per_meal order_total/@runningmenu.total_quantity rescue 0
  json.delivery_room_value @runningmenu.delivery_room_value
  json.headcount_served @runningmenu.headcount_served

  json.share_token @runningmenu.share_token
  json.per_user_copay @runningmenu.per_user_copay
  json.per_user_copay_amount @runningmenu.per_user_copay_amount

  json.remaining_budget @share_meeting.present? ? @runningmenu.user_remaining_budget(nil, @share_meeting.id, nil) : @runningmenu.user_remaining_budget(current_member.id, nil, nil) #.per_meal_budget - user_total_price
  json.price_per_head @runningmenu.orders.active.sum(:total_price) / @runningmenu.orders_count if @runningmenu.buffet?

  if @share_meeting.present? && !@share_meeting.customer_id.present?
    json.customer false
  elsif current_member.present? && (@runningmenu.present? && (@runningmenu.per_user_copay? || current_member.unsubsidized_user?)) && (current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager?) && current_member.profile_completed? && current_member.customer_id.blank?
    json.customer false
  else
    json.customer true
  end
  json.delivery_fee 0
  if current_member.present? && current_member.company_admin?
    invoice = @runningmenu.orders.active.last&.invoice
    if invoice.present?
      json.delivery_fee invoice.line_items.where("item ILIKE '%delivery%'").sum(:amount)
    end
  end

  if @share_meeting.present? || (current_member.present? && (current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager?))
    resource = @share_meeting || current_member
    user_items = resource.orders.active.joins(:fooditem).where(runningmenu_id: @runningmenu.id).pluck("orders.quantity, fooditems.name")
    first_item = user_items.first
    if user_items.count > 0
      json.your_order do
        json.quantity first_item.first
        json.item_name first_item.last
        json.more_items user_items.count-1
      end
    end
  end

  if current_member.present?
    text_field_required = @runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.value = ?', 1, Field.field_types[:text], '')
    if text_field_required.present?
      json.field_required true
    else
      dropdown_field_required = @runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.fieldoption_id IS NULL', 1, Field.field_types[:dropdown])
      json.field_required dropdown_field_required.present?
    end

    json.custom_fields do
      json.array! current_member.company.fields.active.order(position: :asc) do |field|
        json.id field.id
        json.field_type field.field_type
        json.name field.name
        json.required field.required
        requestfield = Runningmenufield.find_by(runningmenu_id: @runningmenu.id, field_id: field.id)

        value = (requestfield.present?) ? field.field_type == 'dropdown' ? '' : requestfield.value : ''
        id = (requestfield.present?) ? requestfield.id : ''
        json.runningmenu_id id
        json.value value

        if field.field_type == 'dropdown'
          json.options do
            json.array! field.fieldoptions.active.order(position: :asc) do |fieldoption|
              json.id fieldoption.id
              json.name fieldoption.name
              json.selected Runningmenufield.exists?(runningmenu_id: @runningmenu.id, field_id: field.id, fieldoption_id: fieldoption.id)
            end
          end
        end
      end
    end
    if current_member.company_admin? && !@runningmenu.orders.active.exists?
      addresses = @runningmenu.addresses.active
      meeting = Runningmenu.joins(:orders).where.not(:id=>@runningmenu.id).where(runningmenus: {company_id: @runningmenu.company_id, runningmenu_type: @runningmenu.runningmenu_type, menu_type: @runningmenu.menu_type}, orders: { status: :active, restaurant_address_id: addresses.pluck(:id)}).where("runningmenus.delivery_at < ?", Time.current).order(delivery_at: :asc).last
      if meeting.present?
        order_ids = []
        json.clone_orders do
          meeting.orders.active.joins(:fooditem).where(orders: {restaurant_address_id: addresses.pluck(:id)}, fooditems: {status: "active"}).each do |order|
            if order.optionsets_orders.blank?
              order_ids << order.id
            elsif order.optionsets.where(:status=>"deleted").blank? && order.optionsets_orders.joins(:options_orders=>:option).where(options_orders: {options: {status: "deleted"}}).blank?
              order_ids << order.id
            end
          end
          order_ids = order_ids.flatten.uniq
          json.delivery_at meeting.delivery_at_timezone
          json.orders_count order_ids.count
          json.order_ids order_ids
        end
      end
    else
      json.clone_orders nil
    end
  end
end
if current_member.present?
  json.custom_fields @runningmenu.runningmenufields.joins(:field).order('fields.position ASC') do |runningmenufield|
    json.id runningmenufield.id
    #json.value runningmenufield.value
    json.field_type runningmenufield.field_type
    json.name runningmenufield.field.name if runningmenufield.field.present?
    json.required runningmenufield.field.required if runningmenufield.field.present?
    #json.runningmenu_id runningmenufield.runningmenu_id
  end

  json.selected_cuisines @runningmenu.cuisines_menus do |cuisines_menu|
    json.id cuisines_menu.id
    json.value cuisines_menu.cuisine.id
    json.label cuisines_menu.cuisine.name
  end
end
