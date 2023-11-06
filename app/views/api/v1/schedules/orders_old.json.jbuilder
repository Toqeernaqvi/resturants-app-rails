if @orders.present?

  json.set! 'order_summary' do
    json.meeting_name @runningmenu.runningmenu_name
    json.meeting_type @runningmenu.runningmenu_type
    json.meeting_style @runningmenu.menu_type
    json.ordered_at @runningmenu.delivery_at
    json.user_copay @runningmenu.per_user_copay
    json.sort_order @sort_order
    json.sort_type @sort_type
    json.address @runningmenu.address
    invoice = @orders.active.last&.invoice
    if invoice.present?
      json.delivery_fee invoice.line_items.where("item ILIKE '%delivery%'").sum(:amount)
      json.invoice_download_link ENV['BACKEND_HOST']+generate_PDF_admin_invoice_path(id: invoice.id, format: :pdf)
    else
      json.delivery_fee 0
      json.invoice_download_link ""
    end
    if current_member.company_user?
      json.restaurant_name @orders.pluck('restaurants.name').uniq.join(', ')
    else
      json.restaurant_name @orders.pluck('restaurants.name').uniq.join(', ')
    end
    if current_member.company_user?
      json.total_price @orders.active.sum(&:user_paid)
    else
      json.total_price @orders.active.sum(:total_price)
    end
    if  @runningmenu.end_time.present?
      json.end_time  @runningmenu.end_time.strftime "%H:%M"
    else
      json.end_time  @runningmenu.delivery_at.strftime "%H:%M"
    end
    menu_type = @runningmenu.menu_type
    total_order_price = @orders.active.sum(:total_price)
    total_order_quantity = @orders.active.where.not(restaurant_address_id: Restaurant.find_by(name: "Beverages & More").addresses.active.first.id).sum(:quantity)
    json.total_quantity @orders.active.sum(:quantity).to_i
    json.cancelled_total_quantity @orders.cancelled.sum(:quantity).to_i
    json.marketplace @runningmenu.marketplace
    json.price_per_head @orders.first.runningmenu.orders_count > 0 ? (@orders.active.sum(:total_price) / @orders.first.runningmenu.orders_count) : 0
    if current_member.company_user?
      # order_count = active_orders.where(user_id: current_member.id).count
      # total_quantity = active_orders.where(user_id: current_member.id).sum(:quantity)
      total_paid = @runningmenu.orders.active.where(user_id: current_member.id).pluck("SUM(orders.user_price) + SUM(CASE WHEN orders.user_markup THEN orders.site_price ELSE 0 END) AS total_user_paid").last
      if total_paid.nil?
        json.order_total nil
      else
        json.order_total total_paid > 0 ? total_paid : 0
      end
      json.meeting_style menu_type unless menu_type == 'individual'
    else
      # order_count = active_orders.count
      # total_quantity = active_orders.sum(:quantity)
      json.meeting_style menu_type
      json.avg_per_meal @orders.active.where.not(restaurant_address_id: Restaurant.find_by(name: "Beverages & More").addresses.active.first.id).sum(:total_price) / total_order_quantity
      json.order_total total_order_price
    end

    json.runningmenu_fields do
      json.array! @orders.first.runningmenu.runningmenufields.joins(:field).order('fields.position ASC') do |runningmenufield|
        json.name runningmenufield.field.name
        if runningmenufield.field_type == 'dropdown'
          json.value runningmenufield.fieldoption.present? ? runningmenufield.fieldoption.name : ""
        else
          json.value runningmenufield.value
        end
      end
    end
  end
  json.enable_grouping_orders @runningmenu.company.enable_grouping_orders
  if (@sort_type=="status" && @sort_order=="ASC") || @sort_type=="item"
    json.set! 'orders' do
      json.array! @orders.includes(:user, :share_meeting, :fooditem, :dishsize, optionsets_orders: [options_orders: [:option]]) do |order|
        json.id order.id
        json.status order.status
        json.group order.group_view
        json.restaurant_name order.restaurant.name
        json.cutoff_at order.runningmenu.cutoff_at
        json.admin_cutoff_at order.runningmenu.admin_cutoff_at
        json.share_meeting order.share_meeting if order.share_meeting.present?
        json.user do
          json.id order.user.id
          json.name order.user.name
          json.email order.user.email
          json.user_type order.share_meeting.present? ? "company_user" : order.user.user_type
        end
        if @runningmenu.buffet?
          json.set! 'fooditem' do
            json.id order.fooditem.id
            json.name order.fooditem.name
            json.description order.fooditem.description
            json.calories order.fooditem.calories
            json.spicy order.fooditem.spicy
            json.best_seller order.fooditem.best_seller
            json.image order.fooditem.image
            json.price order.fooditem.price
            json.gross_price order.fooditem.gross_price
            json.rating_count order.fooditem.rating_count
            json.average_rating order.fooditem.average_rating
            json.skip_markup order.fooditem.skip_markup
            json.dishsize order.dishsize.title
            json.serve_count order.dishsize.serve_count * order.quantity
            json.total_price order.total_price
          end
        else
          json.fooditem order.fooditem
        end
        json.set! 'options' do
          order.optionsets_orders.each do |optionset_order|
            json.array! optionset_order.options_orders do |option_order|
              json.description option_order.option.description
            end
          end
        end
        json.quantity order.quantity
        if current_member.company_user?
          json.user_price order.user_paid
        elsif current_member.company_admin?
          if @runningmenu.buffet?
            price = number_with_precision(order.price, precision: 2)
          else
            price = order.total_price
          end
          json.price price
          json.user_price order.user_paid
          json.company_price order.company_paid * order.quantity
        end
      end
    end
    json.set! 'orders' do
      json.array! @users do |u|
        json.status "unordered"
        json.user do
          json.id u.id
          json.name u.name
          json.email u.email
          json.is_admin u.company_admin?
          json.user_type u.user_type
        end
      end
    end
  elsif @sort_type == "status" && @sort_order == "DESC"
    json.set! 'orders' do
      json.array! @users do |u|
        json.status "unordered"
        json.user do
          json.id u.id
          json.name u.name
          json.email u.email
          json.is_admin u.company_admin?
          json.user_type u.user_type
        end
      end
    end
    json.set! 'orders' do
      json.array! @orders.includes(:user, :share_meeting, :fooditem, :dishsize, optionsets_orders: [options_orders: [:option]]) do |order|
        json.id order.id
        json.status order.status
        json.group order.group_view
        json.restaurant_name order.restaurant.name
        json.cutoff_at order.runningmenu.cutoff_at
        json.admin_cutoff_at order.runningmenu.admin_cutoff_at
        json.share_meeting order.share_meeting if order.share_meeting.present?
        json.user do
          json.id order.user.id
          json.name order.user.name
          json.email order.user.email
          json.user_type order.share_meeting.present? ? "company_user" : order.user.user_type
        end
        if @runningmenu.buffet?
          json.set! 'fooditem' do
            json.id order.fooditem.id
            json.name order.fooditem.name
            json.description order.fooditem.description
            json.calories order.fooditem.calories
            json.spicy order.fooditem.spicy
            json.best_seller order.fooditem.best_seller
            json.image order.fooditem.image
            json.price order.fooditem.price
            json.gross_price order.fooditem.gross_price
            json.rating_count order.fooditem.rating_count
            json.average_rating order.fooditem.average_rating
            json.skip_markup order.fooditem.skip_markup
            json.dishsize order.dishsize.title
            json.serve_count order.dishsize.serve_count * order.quantity
            json.total_price order.total_price
          end
        else
          json.fooditem order.fooditem
        end
        json.set! 'options' do
          order.optionsets_orders.each do |optionset_order|
            json.array! optionset_order.options_orders do |option_order|
              json.description option_order.option.description
            end
          end
        end
        json.quantity order.quantity
        if current_member.company_user?
          json.user_price order.user_paid
        elsif current_member.company_admin?
          if @runningmenu.buffet?
            price = number_with_precision(order.price, precision: 2)
          else
            price = order.total_price
          end
          json.price price
          json.user_price order.user_paid
          json.company_price order.company_paid * order.quantity
        end
      end
    end
  elsif @sort_type == "user"
    json.set! 'orders' do
      json.array! @user_sorting.each do |obj|
        obj_class = obj.keys.last
        obj_type = obj.values.last
        if obj_class == "user"
          u = obj_type
          json.status "unordered"
          json.user do
            json.id u.id
            json.name u.name
            json.email u.email
            json.is_admin u.company_admin?
            json.user_type u.user_type
          end
        elsif obj_class == "order"
          order = obj_type
          json.id order.id
          json.status order.status
          json.group order.group_view
          json.restaurant_name order.restaurant.name
          json.cutoff_at order.runningmenu.cutoff_at
          json.admin_cutoff_at order.runningmenu.admin_cutoff_at
          json.share_meeting order.share_meeting if order.share_meeting.present?
          json.user do
            json.id order.user.id
            json.name order.user.name
            json.email order.user.email
            json.user_type order.share_meeting.present? ? "company_user" : order.user.user_type
          end
          if @runningmenu.buffet?
            json.set! 'fooditem' do
              json.id order.fooditem.id
              json.name order.fooditem.name
              json.description order.fooditem.description
              json.calories order.fooditem.calories
              json.spicy order.fooditem.spicy
              json.best_seller order.fooditem.best_seller
              json.image order.fooditem.image
              json.price order.fooditem.price
              json.gross_price order.fooditem.gross_price
              json.rating_count order.fooditem.rating_count
              json.average_rating order.fooditem.average_rating
              json.skip_markup order.fooditem.skip_markup
              json.dishsize order.dishsize.title
              json.serve_count order.dishsize.serve_count * order.quantity
              json.total_price order.total_price
            end
          else
            json.fooditem order.fooditem
          end
          json.set! 'options' do
            order.optionsets_orders.each do |optionset_order|
              json.array! optionset_order.options_orders do |option_order|
                json.description option_order.option.description
              end
            end
          end
          json.quantity order.quantity
          if current_member.company_user?
            json.user_price order.user_paid
          elsif current_member.company_admin?
            if @runningmenu.buffet?
              price = number_with_precision(order.price, precision: 2)
            else
              price = order.total_price
            end
            json.price price
            json.user_price order.user_paid
            json.company_price order.company_paid * order.quantity
          end
        end
      end
    end
  end

end