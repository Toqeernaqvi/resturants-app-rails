class OrderMailer < ApplicationMailer

  def order_placed(order, refund)
    @refund = refund
    @order = order
    @unsubscribe_link = true
    to = order.share_meeting.present? ? order.share_meeting.email : order.user.email
    subject = @order.cancelled? ? 'Cancelled Order' : (@refund.present? ? 'Updated Order Confirmation' : 'Order Confirmation')
    mail(to: to, subject: "#{subject} for " + order.runningmenu.delivery_at_timezone.strftime('%B %d, %Y'))
  end

  def order_detail(user, order)
    @order = order
    mail(to: user.email, subject: "Chowmill order dated: " + order.runningmenu.delivery_at_timezone.strftime('%B %d, %Y'))
  end

  def order_rating(ratingable, item)
    @item = item
    @ratingable = ratingable
    mail(to: ENV['ORDERS_EMAIL'], subject: "Chowmill Order rating ")
  end

  def vendor_order_rating(ratingable, item, restaurant_admin)
    @item = item
    @ratingable = ratingable
    mail(to: restaurant_admin.email, subject: "Chowmill Customer Rating: #{ratingable.name.titleize} ")
  end

  def company_order_detail(user, runningmenu, orders, user_price, share_meeting = nil)
    @unsubscribe_link = true
    @runningmenu = runningmenu
    @user = user
    @orders = orders.includes(:fooditem, optionsets_orders: [options_orders: [:option]]).joins(:user).where("orders.user_id = #{user.id}").order("orders.group ASC, users.first_name ASC, users.last_name ASC")
    @total_order_quantity = orders.sum(:quantity).to_i
    @ordered_at = runningmenu.delivery_at_timezone
    @share_meeting = share_meeting
    @enable_grouping_orders_check = @share_meeting.present? ? @share_meeting.runningmenu.company.enable_grouping_orders : user.company.enable_grouping_orders rescue false
    @user_price = user_price
    
    if user_price && ((user.present? && (user.company_user? || user.unsubsidized_user? || user.company_manager?)) || share_meeting.present?)
      @total_order_amount = orders.sum{|order| order.user_paid > 0 ? (order.user_paid +  0.30)/(1-0.029) > 0.50 ? ((order.user_paid +  0.30)/(1-0.029)).round(2) : 0.50 : 0}
    elsif user.present? && user.company_admin?
      @total_order_amount = orders.sum(:total_price) - orders.sum(:user_paid)
    else
      @total_order_amount = 0.0
    end
    if @user.present? && @user.company_admin?
      subject = "#{@runningmenu.runningmenu_name.present? ? @runningmenu.runningmenu_name : ''} Order Summary for " + @runningmenu.runningmenu_type.capitalize + " on "+ @ordered_at.to_time.in_time_zone(@runningmenu.company.time_zone).strftime('%B %d, %Y')
    else
      subject = "Chowmill Orders for " + @ordered_at.to_time.in_time_zone(@runningmenu.company.time_zone).strftime('%B %d, %Y')
    end
    if share_meeting.present?
      mail(to: share_meeting.email, subject: subject)
    else
      mail(to: user.email, subject: subject)
    end
  end

  def no_order_placed(user, runningmenu)
    @runningmenu = runningmenu
    @user = user
    @menu_items = get_menu_items(user, runningmenu)
    @confirmed = if user.confirmed? && user.profile_completed == "yes"
      true
    else
      @link = ENV['FRONTEND_HOST'] + '/user/invite/invite_code/' + user.confirmation_token
      false
    end
    mail(to: user.email, subject: "You're Missing Out: " + runningmenu.delivery_at_timezone.strftime('%B %d, %Y'))
  end

  def no_order_placed_last_chance(user, runningmenu)
    @runningmenu = runningmenu
    @user = user
    @menu_items = get_menu_items(user, runningmenu)
    @confirmed = if user.confirmed? && user.profile_completed == "yes"
      true
    else
      @link = ENV['FRONTEND_HOST'] + '/user/invite/invite_code/' + user.confirmation_token
      false
    end
    mail(to: user.email, subject: "Last Chance to Order " + runningmenu.runningmenu_type + " for " + runningmenu.delivery_at_timezone.strftime('%B %d, %Y'))
  end

  def get_menu_items(user, runningmenu)
    p_params = "p_s3_base_url := 'https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com'::TEXT, p_runningmenu_id := #{runningmenu.id}, p_company_id := #{runningmenu.company_id}, p_current_user_id := #{user.id}"
    sql = "SELECT * FROM menus(#{p_params})"
    menus = ActiveRecord::Base.connection.execute(sql)
    menus = FetchMenus.call(user, menus.first["menus"])

    filters = "orders.restaurant_address_id IN (#{runningmenu.addresses.pluck(:id).join(',')})"
    orders = Order.find_by_sql("SELECT * FROM (SELECT DISTINCT ON(fooditem_id) orders.* FROM orders JOIN runningmenus ON runningmenus.id = orders.runningmenu_id JOIN restaurants ON orders.restaurant_id = restaurants.id JOIN fooditems ON fooditems.id = orders.fooditem_id WHERE runningmenus.status = #{Runningmenu.statuses[:approved]} AND runningmenus.delivery_at < '#{Time.current.to_s(:db)}' AND restaurants.name != '#{ENV['BEV_AND_MORE']}' AND fooditems.status = #{Fooditem.statuses[:active]} AND orders.user_id = #{user.id} AND orders.status = #{Order.statuses[:active]} AND #{filters}) AS t ORDER BY t.created_at DESC LIMIT 10")
    total_fooditems = orders.pluck(:fooditem_id)
    total_fooditems += menus["restaurants"]&.collect{|f| f["sections"]&.collect{|s| s["fooditems"]}}&.flatten&.collect{|f| f["id"] }&.compact
    total_fooditems = total_fooditems&.uniq&.count
    total_resaurants = orders.pluck(:restaurant_id)
    total_resaurants += menus["restaurants"]&.collect{|r| r["id"] }&.compact
    total_resaurants = total_resaurants&.uniq&.count
    { total_resaurants: total_resaurants, total_fooditems: total_fooditems,
      most_popular: {total: menus["most_popular"].count, fooditems: menus["most_popular"]&.collect{|f| {"id" => f["id"], "name" => f["name"], "restaurant_name" => f["restaurant_name"],"price" => f["price"], "image_url" => f["image"]["url"], "average_rating" => f["average_rating"] } }&.take(3) },
      top_picks: {total: menus["new_section"][:fooditems]&.count.to_i, fooditems: (menus["new_section"][:fooditems]&.collect{|f| {"id" => f["id"], "name" => f["name"], "restaurant_name" => f["restaurant_name"], "price" => f["price"], "image_url" => f["image"]["url"], "average_rating" => f["average_rating"] } }&.take(2) rescue nil) },
      order_it_again: {total: orders.count, fooditems: orders&.take(2)&.collect{|o| {"id" => o.fooditem.id, "name" => o.fooditem.name, "restaurant_name" => o.restaurant.name, "image_url" => o.fooditem.image_url, "average_rating" => o.fooditem.average_rating,"price" => o.fooditem.price} }.take(2) }
    }
  end

  def self.returnPercentRating(rating, starNumber)
    str = "0%"
    if rating >= starNumber
      str = '100%'
    elsif (starNumber - rating) < 1
      str = "#{((rating - rating.floor) * 100)}%"
    end
    str
  end

  def card_charged(email, orders)
    @orders = orders
    mail(to: email, subject: "Your Card Has Been Charged ")
  end

  def card_charged_error(orders, error)
    @orders = orders
    @error = error
    mail(to: "#{ENV['FINANCE_EMAIL']}", subject: "Card Charge Aborted")
  end

  def card_charge_failed(email, orders, error, attempts_count, meeting)
    @orders = orders
    @error = error
    @share_meeting = meeting
    mail(to: email, subject: "Billing Failure | Attempt # #{attempts_count}")
  end

  def survey_alert(order, runningmenu)
    #@user = user
    @order = order
    mail(to: order.user.email, subject: "How was your food today?")
  end

  def admin_survey_alert(order, runningmenu)
    #@user = user
    @order = order
    mail(to: order.user.email, subject: "How was the delivery today?")
  end

  def orders_diff_at_admin_cuttof(runningmenu, orders)
    @runningmenu = runningmenu
    @orders = orders
    mail(to: ENV['ORDERS_EMAIL'], subject: "Admin Cutoff Reached: #{runningmenu.company.name} - #{@orders.count} Orders Changed")
  end

  def orders_at_cutoff(user, ordered_at, orders)
    @orders = orders.active.joins(:user).order("orders.group ASC, users.first_name ASC, users.last_name ASC")
    @ordered_at = ordered_at
    @enable_grouping_orders_check = user.company.enable_grouping_orders rescue false
    @user = user
    @price_column_check = false
    mail(to: user.email, subject: "#{orders.first.runningmenu.runningmenu_name.present? ? orders.first.runningmenu.runningmenu_name : ''} Order Summary for " + orders.first.runningmenu.runningmenu_type.capitalize + " on "+ ordered_at.to_time.strftime('%B %d, %Y'))
  end

  def paid_orders(restaurant_admin, orders)
    @orders = orders
    mail(to: restaurant_admin.email, subject: "Paid Orders")
  end

  def invoice_check(orders)
    @orders = orders.group_by{ |o| o.created_at.in_time_zone(o.runningmenu.company.time_zone).to_date }
    mail(to: ENV['FINANCE_EMAIL'], subject: "Orders not billed in any invoice")
  end

  def missing_restaurant_billing(orders)
    @orders = orders.group_by{ |o| o.created_at.in_time_zone(o.runningmenu.company.time_zone).to_date }
    mail(to: ENV['FINANCE_EMAIL'], subject: "Orders not billed in any restaurant billing")
  end

end
