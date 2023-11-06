json.runningmenu do
  json.runningmenu_name @runningmenu.runningmenu_name
  json.restaurant_name @orders.last.restaurant.name
  address = @orders.last.restaurant_address
  json.enable_self_service address.enable_self_service
  json.address_line address.address_line
  json.street address.street_number
  json.street address.street
  json.suite_no address.suite_no
  json.city address.city
  json.state address.state
  json.zip address.zip
  json.menu_type @runningmenu.runningmenu_type
  json.style @runningmenu.menu_type
  json.items_count @orders.active.sum(:quantity)
  json.delivery_type @runningmenu.delivery_type
  json.delivery_at @runningmenu.delivery_at_timezone
  json.pick_up_time @runningmenu.pickup_at_timezone.strftime("%I:%M %p")
  json.cutoff_at @runningmenu.cutoff_at_timezone
  json.admin_cutoff_at @runningmenu.admin_cutoff_at_timezone
  json.delivery_instructions @runningmenu.delivery_instructions
  json.driver_id @runningmenu.driver_id
  json.driver_name @runningmenu.driver_id.present? ? @runningmenu.driver.name : nil
  billing = OrderHelper.orders_billing(@orders.active)
  json.sub_total billing["sub_total"]
  json.tax billing["sale_tax"]
  json.tax_percentage billing["sale_tax_percentage"]
  json.commission billing["commission"]
  json.commission_percentage billing["discount_percentage"]
  json.delivery_cost billing["delivery_cost"]
  json.total_payout billing["payout_total"]
  json.rejected_by_vendor @address_runningmenu.rejected_by_vendor
  json.reject_reason @address_runningmenu.reject_reason
  json.orders_accepted @address_runningmenu.orders_acknowledge?
  json.changes_accepted @address_runningmenu.changes_acknowledge?
  json.receipt_acknowledge @address_runningmenu.receipt_acknowledge?
  json.summary_url @address_runningmenu.summary_pdf.present? ? ENV["CLOUDFRONT_URL"]+"/"+@address_runningmenu.summary_pdf : nil
  json.labels_url @address_runningmenu.summary_labels.present? ? ENV["CLOUDFRONT_URL"]+"/"+@address_runningmenu.summary_labels : nil
  json.restaurant_coordinates [address.latitude, address.longitude]
  json.company_coordinates [@runningmenu.address.latitude, @runningmenu.address.longitude]
  json.distance Distance.calculate([address.latitude, address.longitude], [@runningmenu.address.latitude, @runningmenu.address.longitude])
end
json.company do
  json.id @runningmenu.company.id
  json.name @runningmenu.company.name
  json.enable_saas @runningmenu.company.enable_saas
  json.address_line @runningmenu.address.location
end
json.company_admin do
  user = @runningmenu.user
  json.id user.id
  json.first_name user.first_name
  json.last_name user.last_name
  json.email user.email
  json.phone_number user.phone_number
end
json.sort_by @sort_by == 'name' ? 'item' : @sort_by
json.sort_type @sort_type
user_orders = false
if @orders.joins(:user).where("users.user_type IN(#{User.user_types[:company_user]}, #{User.user_types[:company_manager]}, #{User.user_types[:unsubsidized_user]})").present?
  user_orders = true
end
modified = false
json.orders @orders.each do |order|
  if @orders.last.runningmenu.buffet?
    json.id order.id
    removed = added = 0
    if order.cancelled? && !order.latest_version_id.blank?
      removed += order.quantity
    elsif !order.latest_version_id.blank?
      if order.versions.first.changeset[:quantity].present? && order.versions.first.changeset[:quantity][0].nil?
        added += order.quantity
      else
        start_limit = end_limit = nil
        if order.versions.present? && order.versions.first.changeset[:quantity].present? && !order.versions.first.changeset[:quantity][0].nil?
          start_limit = order.versions.first.changeset[:quantity][0]
        end

        if order.versions.last.changeset[:quantity].present?
          end_limit = order.versions.last.changeset[:quantity][1]
        end
        if start_limit.present? && end_limit.present?
          if start_limit < end_limit
            added += (end_limit - start_limit)
          elsif start_limit > end_limit
            removed += (start_limit - end_limit)
          end
        end
      end
    end

    if added > removed
      json.added added - removed
      modified = true
    elsif added < removed
      json.removed removed - added
      modified = true
    end
    json.dish_size order.dishsize.title
    json.serves order.dishsize.serve_count
    json.quantity order.quantity
    json.item do
      json.name order.fooditem.name
      json.description order.fooditem.description
      order.optionsets_orders.each do |optionsets_order|
        json.options do
          json.array! optionsets_order.options_orders.map {|options_order| options_order.option&.description }
        end
      end
    end
    dishsize = order.fooditem.dishsize_fooditems.where(:dishsize_id=>order.dishsize_id).last
    price = dishsize.present? ? dishsize.price : 0
    json.price price
    json.total_price price * order.quantity
  else
    json.id order.id
    removed = added = 0
    if order.cancelled? && !order.latest_version_id.blank?
      removed += order.quantity
    elsif !order.latest_version_id.blank?
      if order.versions.first.changeset[:quantity].present? && order.versions.first.changeset[:quantity][0].nil?
        added += order.quantity
      else
        start_limit = end_limit = nil
        if order.versions.present? && order.versions.first.changeset[:quantity].present? && !order.versions.first.changeset[:quantity][0].nil?
          start_limit = order.versions.first.changeset[:quantity][0]
        end

        if order.versions.last.changeset[:quantity].present?
          end_limit = order.versions.last.changeset[:quantity][1]
        end
        if start_limit.present? && end_limit.present?
          if start_limit < end_limit
            added += (end_limit - start_limit)
          elsif start_limit > end_limit
            removed += (start_limit - end_limit)
          end
        end
      end
    end

    if added > removed
      json.added added - removed
      modified = true
    elsif added < removed
      json.removed removed - added
      modified = true
    end

    if user_orders
      json.user_name order.share_meeting_id.present? ? order.share_meeting.name : order.user.name
    end
    json.status order.status
    if order.runningmenu.individual?
      json.updated_at order.updated_at
      json.quantity order.quantity
      json.item do
        json.name order.fooditem.name
        json.description order.fooditem.description
        order.optionsets_orders.each do |optionsets_order|
          json.options do
            json.array! optionsets_order.options_orders.map {|options_order| options_order.option&.description }
          end
        end
        json.remarks order.remarks
      end
      # if order.optionsets_orders.present?
      #   price = 0.0
      #   order.optionsets_orders.each do |optionsets_order|
      #     if optionsets_order.present?
      #       price += optionsets_order.options_orders.map{|o| o.option&.price.to_f}.sum
      #     end
      #   end
      #   json.price order.fooditem.price + price
      #   json.total_price (order.fooditem.price + price) * order.quantity
      # else
      #   json.price order.fooditem.price
      #   json.total_price order.fooditem.price * order.quantity
      # end

      # we don't need to check price from order.optionsets_orders because in Orders table we have a column food_price
      # in which we stored actual value + optionstes price. The main advantage of food_price column is we store fooditem price according to #current time or if we update fooditem table that's price will not changed

      json.price order.food_price
      json.total_price  order.food_price_total

    elsif order.runningmenu.buffet?
      json.updated_at order.updated_at
      json.quantity order.quantity
      json.item do
        json.name order.fooditem.name
        json.description order.fooditem.description
        order.optionsets_orders.each do |optionsets_order|
          json.options do
            json.array! optionsets_order.options_orders.map {|options_order| options_order.option&.description }
          end
        end
        json.remarks order.remarks
      end
    end
  end

  # json.price order.optionsets_order.options_orders.present? ? ( order.fooditem_price + order.options_price ) : order.fooditem_price
  # json.total_price order.total_price
end

json.modified modified
