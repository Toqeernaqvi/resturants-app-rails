json.runningmenu do
  json.(
    @runningmenu, :id, :runningmenu_name, :runningmenu_type, :menu_type, :delivery_at, :address_id, :activation_at, :cutoff_at, :admin_cutoff_at, :status,:special_request, :per_meal_budget, :remaining_time, :delivery_room_value, :share_token, :per_user_copay, :per_user_copay_amount, :headcount_served
  )
  json.end_time @runningmenu.formated_end_time
  json.approximate_count @runningmenu.orders_count
  json.price_per_head @runningmenu.orders.active.sum(:total_price) / @runningmenu.orders_count
  json.order_total @runningmenu.orders.active.sum(:total_price)
  field_required = @runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.value = ?', 1, Field.field_types[:text], '')
  if field_required.present?
    json.field_required field_required.present?
  else
    field_required = @runningmenu.runningmenufields.joins(:field).where('fields.required = ? AND  runningmenufields.field_type = ? AND runningmenufields.fieldoption_id IS NULL', 1, Field.field_types[:dropdown])
    json.field_required field_required.present?
  end

  if @share_meeting.present?
    json.order_count @share_meeting.orders.active
    json.total_quantity @share_meeting.orders.active.sum(:quantity).to_i
    json.order_total @share_meeting.orders.active.sum(:total_price)
    total_orders = @runningmenu.orders.active.where.not(restaurant_address_id: Restaurant.find_by(name: ENV['BEV_AND_MORE']).addresses.active.first.id)
    total_order_price = total_orders.sum(:total_price)
    total_order_quantity = total_orders.sum(:quantity).to_i
    avg_per_meal = total_order_price / total_order_quantity
    json.avg_per_meal avg_per_meal
  end

  if @share_meeting.present? && (!@share_meeting.customer_id.present? || !@share_meeting.valid_card)
    json.customer false
    json.pending @share_meeting.user_price
    json.valid_card @share_meeting.valid_card
  elsif current_member.present? && (@runningmenu.present? && @runningmenu.per_user_copay?) && current_member.company_user? && current_member.profile_completed? && (current_member.customer_id.blank? || !current_member.valid_card)
    json.customer false
    json.pending current_member.pending_total
    json.valid_card current_member.valid_card
  else
    json.customer true
  end

  json.display_nutritionix Setting.latest.display_nutritionix
end
# json.company @runningmenu.company
arr = []
restaurant_fooditems_arr = []
company_id = current_member.present? ? current_member.company_id : @share_meeting.runningmenu.company_id
json.restaurants do
  json.array! @runningmenu.addresses.sort_by{|address| address.addressable.name == ENV['BEV_AND_MORE'] ? 1 : 0} do |address|
    json.id address.addressable.id
    json.name address.addressable.name
    json.address_id address.id
    json.address_name address.addressable.name
    if @runningmenu.buffet? && (@share_meeting.present? || current_member.company_user?)
      sections_orders = Order.active.where(restaurant_address_id: address.id, runningmenu_id: @runningmenu.id).joins(:fooditem => :sections).select("sections.section_type AS s_type, sections.name AS s_name, orders.*")
      sorted_orders = sections_orders.sort_by{|s| s.s_type}
      json.sections sorted_orders.group_by{|o| [o.s_type, o.s_name]}.each do |key, orders|
        json.section_type Section.section_types.keys[key[0]].gsub('_', ' ').titleize
        json.section_name key[1]
        json.fooditems orders.each do |order|
          json.id order.fooditem.id
          json.name order.fooditem.name
          json.description order.fooditem.description
          json.calories order.fooditem.calories
          json.spicy order.fooditem.spicy
          json.best_seller order.fooditem.best_seller
          json.image order.fooditem.image
          json.options order.optionsets_orders.joins(:options_orders => :option).where("options.description IS NOT NULL").pluck("options.description").join(', ')
          json.dietaries do
            json.array! order.fooditem.dietaries.uniq do |dietary|
              json.name dietary.name
            end
          end
          json.ingredients do
             json.array! order.fooditem.ingredients.uniq do |ingredient|
               json.name ingredient.name
             end
          end
        end
      end
    else
      menu = address.menus.active.find_by(menu_type: @runningmenu.buffet? ? 'buffet' : @runningmenu.runningmenu_type)
      if menu.present?
        if params[:r].present?
          sections = menu.sections.active.where(id: params[:r]).order('position ASC')
        else
          sections = menu.sections.active.sort_by{|s| Section.section_types[s.section_type]}
          # sections = menu.sections.active.order('position ASC')
        end

        if menu.fooditems.present?
          restaurant_fooditems_arr.push(1)
        else
          json.restaurant_fooditems false
        end

      if sections.count > 0
        json.sections do
          json.array! sections do |section|
            if params[:d].present?
              fooditems = section.fooditems.active
                .joins("INNER JOIN dietaries_fooditems ON dietaries_fooditems.fooditem_id = fooditems.id")
                .where(params[:d].map{|d| 'dietary_id = ' + d}.join(' OR '))
                .order(image: :desc)
                .distinct
            else
              fooditems = section.fooditems.active.order(image: :desc)
            end
            if params[:i].present?
              fooditems = fooditems.active
                .joins("INNER JOIN fooditems_ingredients ON fooditems_ingredients.fooditem_id = fooditems.id")
                .where(params[:i].map{|i| 'ingredient_id = ' + i}.join(' OR '))
                .order(image: :desc)
                .distinct
              end

              if fooditems.count > 0
                json.id section.id
                json.name section.name
                json.description section.description
                json.section_type section.section_type.gsub('_', ' ').titleize if @runningmenu.buffet?
                remaining_amount = 0
                share_meeting_remaining_amount = 0
                if current_member && current_member.company_user?
                  remaining_amount = @runningmenu.orders.active.joins(:runningmenu).where("runningmenus.company_id = ? AND orders.user_id = ?", company_id, current_member.id).sum(:total_price)
                end
                if @share_meeting.present?
                  share_meeting_remaining_amount = @runningmenu.orders.active.joins(:runningmenu).where("runningmenus.company_id = ? AND orders.share_meeting_id = ?", company_id, @share_meeting.id).sum(:total_price)
                end
                json.fooditems do
                  json.array! fooditems.includes(:dietaries, :ingredients) do |fooditem|
                    if @runningmenu.buffet? || (fooditem.ignore_budget && current_member && current_member.company_admin?) ||
                      current_member && current_member.company_admin? && ((fooditem.gross_price + @runningmenu.company.markup) <= @runningmenu.scheduler_budget || @runningmenu.per_user_copay?) ||
                      (current_member && current_member.company_user? && (@runningmenu.per_user_copay? || ((fooditem.skip_markup? ? fooditem.gross_price : (fooditem.gross_price + @runningmenu.company.markup)) <= ((fooditem.skip_markup? ? @runningmenu.per_meal_budget : @runningmenu.scheduler_budget)) ))) || (@share_meeting.present? && ((fooditem.skip_markup? ? fooditem.gross_price : (fooditem.gross_price + @runningmenu.company.markup))) <= ((fooditem.skip_markup? ? @runningmenu.per_meal_budget : @runningmenu.scheduler_budget)))

                      if (current_member && current_member.company_user? && !@runningmenu.per_user_copay? && (((fooditem.skip_markup? ? fooditem.gross_price : (fooditem.gross_price + @runningmenu.company.markup)) > ((fooditem.skip_markup? ? @runningmenu.per_meal_budget : @runningmenu.scheduler_budget) - remaining_amount) ))) || (@share_meeting.present? && !@runningmenu.per_user_copay? && ((fooditem.skip_markup? ? fooditem.gross_price : (fooditem.gross_price + @runningmenu.company.markup))) > ((fooditem.skip_markup? ? @runningmenu.per_meal_budget : @runningmenu.scheduler_budget) - share_meeting_remaining_amount))
                        # arr.push(fooditem.id)
                        json.in_budget false
                      end
                      json.fooditem fooditem
                      ordered_quantity = @runningmenu.orders.active.joins(:runningmenu).where("runningmenus.company_id = ?", company_id).where(fooditem_id: fooditem.id).sum(:quantity).to_i
                      json.ordered_quantity ordered_quantity
                      json.dietaries do
                        json.array! fooditem.dietaries.uniq do |dietary|
                          json.id dietary.id
                          json.name dietary.name
                        end
                      end

                      json.ingredients do
                        json.array! fooditem.ingredients.uniq do |ingredient|
                          json.id ingredient.id
                          json.name ingredient.name
                        end
                      end

                      json.dishsizes do
                        json.array! fooditem.dishsizes.active.uniq do |dishsize|
                          json.(
                            dishsize, :id, :title, :description, :serve_count
                          )
                          json.price fooditem.dishsize_fooditems.find_by(dishsize_id: dishsize.id).price + (fooditem.skip_markup ? 0 : ((fooditem.dishsize_fooditems.find_by(dishsize_id: dishsize.id).price * @runningmenu.company.buffet_addons_markup) / 100))
                        end
                      end

                      json.optionsets do
                        json.array! fooditem.optionsets.includes(options:[:dietaries, :ingredients]).where(options: { status: Option.statuses[:active]}).active.order('optionsets.position ASC') do |optionset|
                          json.id optionset.id
                          json.name optionset.name
                          json.required optionset.required
                          json.start_limit optionset.start_limit
                          json.end_limit optionset.end_limit

                          json.options do
                            json.array! optionset.options.active.order('position ASC') do |option|
                              json.id option.id
                              json.description option.description
                              json.price option.price
                              json.calories option.calories

                              json.dietaries do
                                json.array! option.dietaries.uniq do |dietary|
                                  json.id dietary.id
                                  json.name dietary.name
                                end
                              end

                              json.ingredients do
                                json.array! option.ingredients.uniq do |ingredient|
                                  json.id ingredient.id
                                  json.name ingredient.name
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

json.remaining_budget do
  if current_member && current_member.company_user?
    json.remaining_budget @runningmenu.user_remaining_budget(current_member.id, nil, nil)
    # json.in_budget false unless arr.present? && restaurant_fooditems_arr.present?
  elsif @share_meeting.present?
    json.remaining_budget @runningmenu.user_remaining_budget(nil, @share_meeting.id, nil)
    json.in_budget false unless arr.present? && restaurant_fooditems_arr.present?
  end
end

# json.booked do
#   if current_member && current_member.company_user?
#     orders = active_orders.where(user_id: current_member.id).select('id, remarks, quantity, fooditem_id, share_meeting_id')
#   elsif @share_meeting.present?
#     orders = @share_meeting.orders.active.select('id, remarks, quantity, fooditem_id, share_meeting_id')
#   else
#     orders = active_orders.select('id, remarks, quantity, fooditem_id, share_meeting_id')
#   end
#   json.array! orders.all do |booked|
#     json.(
#       booked,
#       :id, :remarks, :quantity, :share_meeting, :fooditem
#     )
#     json.set! 'options' do
#       booked.optionsets_orders.each do |optionset_order|
#         json.array! optionset_order.options_orders do |option_order|
#           json.description option_order.option.description
#         end
#       end
#     end
#     json.cutoff_at @runningmenu.cutoff_at
#     json.admin_cutoff_at @runningmenu.admin_cutoff_at
#   end
# end
#
# json.dietaries do
#   json.array! Dietary.active.all do |dietary|
#     json.(
#       dietary,
#       :id, :name
#     )
#   end
# end
#
# json.ingredients do
#   json.array! Ingredient.active.all do |ingredient|
#     json.(
#       ingredient,
#       :id, :name
#     )
#   end
# end

json.restaurants_addresses do
  json.array! @runningmenu.addresses.includes(addressable:[:cuisines], menus:[:sections]).active do |address|
    if address.addressable.cuisines.present?
      json.name address.addressable.name + ': ' + address.addressable.cuisines.map(&:name).join(", ")
    else
      json.name address.addressable.name
    end
    json.address address
    menu = address.menus.find_by(menu_type: @runningmenu.buffet? ? @runningmenu.menu_type : @runningmenu.runningmenu_type)
    if menu.present?
      sections = menu.sections.active
      # if params[:r].present?
      #   sections = menu.sections.active.where(id: params[:r])
      # else
      #   sections = menu.sections.active
      # end

      if sections.count > 0
        json.sections do
          json.array! sections do |section|
            json.id section.id
            json.name section.name
          end
        end
      end
    end
  end
end

# json.custom_fields do
#   if @runningmenu.present? && @runningmenu.runningmenufields.present?
#     json.array! @runningmenu.runningmenufields do |runningmenufield|
#       if runningmenufield.field.present?
#         json.runningmenu_id runningmenufield.id
#         json.id runningmenufield.field.id if runningmenufield.field.id.present?
#         json.field_type runningmenufield.field_type if runningmenufield.field_type.present?
#         json.name runningmenufield.field.name if runningmenufield.field.present?
#         json.required runningmenufield.field.required if runningmenufield.field.present?
#         json.value runningmenufield.value
#
#         if runningmenufield.field_type == 'dropdown'
#           json.options do
#             json.array! runningmenufield.field.fieldoptions.active do |fieldoption|
#               json.id fieldoption.id
#               json.name fieldoption.name
#               json.selected fieldoption.id == runningmenufield.fieldoption_id
#             end
#           end
#         end
#       end
#     end
#   else
#     company = current_member.company || @share_meeting.runningmenu.company
#     json.array! company.fields.active do |field|
#       json.id field.id
#       json.field_type field.field_type
#       json.name field.name
#       json.required field.required
#
#       if company.orders.present?
#         orderfield = Runningmenufield.find_by(runningmenu_id: company.orders.last.runningmenu.id, field_id: field.id)
#         value = (orderfield.present?) ? orderfield.value : ''
#         json.value value
#       else
#         json.value ''
#       end
#
#       if field.field_type == 'dropdown'
#         json.options do
#           json.array! field.fieldoptions.active do |fieldoption|
#             json.id fieldoption.id
#             json.name fieldoption.name
#
#             if company.orders.present?
#               json.selected Runningmenufield.exists?(runningmenu_id: company.orders.last.runningmenu.id, field_id: field.id, fieldoption_id: fieldoption.id)
#             else
#               json.selected false
#             end
#           end
#         end
#       end
#     end
#   end
# end
