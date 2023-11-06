class Api::V1::Vendor::RestaurantsController < Api::V1::Vendor::ApiController
  before_action :set_restaurant, only: [:show, :update, :update_settings, :admins] #, :delivery_dates
  skip_before_action :authenticate_active_user, only: [:acknowledge_schedule, :accept_orders], if: lambda { params[:token].present?}
  before_action :validate_admin, only: [:orders]#, :accept_orders]
  # before_action :set_runningmenu, only: [:summary_excel]
  before_action :total_orders, only: [:meetings]

  def update
    if @restaurant.update(restaurant_params.merge(updated_from_frontend: true))
      render :show
    else
      error(E_INTERNAL, @restaurant.errors.full_messages[0])
    end

    # @restaurant = RestaurantAddress.find(current_member.address_id)
    # if @restaurant.update(restaurant_params)
    #   render :index
    # else
    #   render :json => {
    #     status: 404,
    #     message: "#{@restaurant.errors.full_messages}"
    #   }, status: 404
    # end
  end

  def update_settings
    if @restaurant.update(restaurant_params.merge(updated_from_frontend: true))
      if @restaurant.addressable.update(restaurant_addressable_params)
        render :show
      else
        error(E_INTERNAL, @restaurant.addressable.errors.full_messages[0])
      end
    else
      error(E_INTERNAL, @restaurant.errors.full_messages[0])
    end
  end

  def index
    # @restaurant = RestaurantAddress.find(current_member.address_id)
    @restaurants = current_member.addresses
    @restaurant = current_member.addresses.last.addressable
  end

  def show
  end

  # def delivery_dates
  #   delivery_dates = @restaurant.runningmenus.order(delivery_at: :asc).pluck("DATE(delivery_at)").uniq
  #   render json: delivery_dates
  # end

  def admins
    @restaurant_admins = @restaurant.admins.active.order("(CASE WHEN users.id = #{current_member.id} THEN TRUE ELSE FALSE END) DESC")
  end

  def update_admin
    restaurant_admin = User.find params[:id]
    if restaurant_admin.update(restaurant_admin_params)
      render json: {id: restaurant_admin.id, first_name: restaurant_admin.first_name, last_name: restaurant_admin.last_name, email: restaurant_admin.email, phone_number: restaurant_admin.phone_number, fax: restaurant_admin.fax, fax_summary_check: restaurant_admin.fax_summary_check, email_summary_check: restaurant_admin.email_summary_check, email_label_check: restaurant_admin.email_label_check, send_text_reminders: restaurant_admin.send_text_reminders}
    else
      error(E_INTERNAL, restaurant_admin.errors.full_messages[0])
    end
  end

  def meetings
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["id"].to_i) rescue nil
    if authorized_current_member.present?
      @ids = params[:address_ids].join(",")
      @start_date = params[:start_date].in_time_zone(current_member.time_zone).beginning_of_day.utc.to_s(:db)
      @end_date = params[:end_date].in_time_zone(current_member.time_zone).at_end_of_day.utc.to_s(:db)
      sql = "SELECT * FROM sp_restaurant_orders(p_current_user_id := #{current_member.id}, p_start_date := '#{@start_date}', p_end_date := '#{@end_date}', p_address_ids := '#{@ids}')"
      result = ActiveRecord::Base.connection.exec_query(sql)
      result = result.first["sp_restaurant_orders"]
      if result.present?
        meetings = JSON.parse(result)
        meetings= meetings.group_by { |m| m["pickup"].to_date }.transform_values do |meeting|
          meeting.group_by { |meeting| meeting["restaurant_name"] }
        end
        render :json => {
          deliveries: meetings,
          total_orders: @orders,
        }
      else
        render json: {message: "No record found.", total_orders: @orders}
      end
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def orders
    @sort_by = params[:sort_by].present? ? params[:sort_by] == "item" ? "name" : params[:sort_by] : "orders.updated_at"
    @sort_type = params[:sort_type].present? ? params[:sort_type] : "DESC"
    @orders = Order.joins(:fooditem).where(restaurant_address_id: params[:id], runningmenu_id: params[:meeting_id]).order("#{@sort_by} #{@sort_type}")
    @address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: params[:meeting_id], address_id: params[:id])
    @runningmenu = Runningmenu.find_by_id(params[:meeting_id])
    unless @orders.present?
      render json: {message: "No orders present"}
    end
  end

  def get_summary_pdf
    scheduler = Runningmenu.find_by_id params[:meeting_id]
    if scheduler.orders.active.present?
      path = []
      orders = []
      counter = 0
      user = false
      address_id = params[:id]
      delivery_at = scheduler.delivery_at_timezone
      orders = Order.order_summary(scheduler, true, 0, 0, address_id.to_i)
      template_path = scheduler.buffet? ? "admin/orders/buffetsummarypdf.html.erb" : "admin/orders/ordersummarypdf.html.erb"
      render pdf: "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{delivery_at.strftime('%a, %d %b %Y %H:%M:%S')}", template: template_path, locals: { orders: orders, delivery_at: delivery_at, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p"), runningmenu: scheduler, address_id: address_id }
    else
      render json: {message: "No orders yet"}, status: 403
    end
  end

  def summary_excel
    @delivery_date = params[:delivery_date].in_time_zone(current_member.time_zone).beginning_of_day.utc.to_s(:db)..params[:delivery_date].in_time_zone(current_member.time_zone).at_end_of_day.utc.to_s(:db)
    @p_delivery_date = params[:delivery_date].to_date.strftime('%A, %B %d, %Y')
    @orders = Order.active.joins(:runningmenu).where(restaurant_address_id: params[:restaurant_address_ids], runningmenus: {delivery_at: @delivery_date})
    if @orders.exists?
      respond_to do |format|
        format.xlsx do
          filename = 'Chowmill Orders - ' + params[:delivery_date].to_date.strftime('%b %d %Y')
          template_path = 'admin/orders/ordersummaryexcel.xlsx.axlsx'
          render xlsx: "#{filename}", template: template_path
        end
      end
    else
      render json: {message: "No orders yet"}, status: 403
    end    
  end

  def get_labels
    FileUtils.mkdir_p 'public/summary'
    FileUtils.mkdir_p 'public/summaryzip'
    scheduler = Runningmenu.find_by_id params[:meeting_id]
    if scheduler.orders.active.present?
      respond_to do |format|
        format.docx do
          orders = []
          restaurant_address_id = params[:restaurant_address_id]
          delivery_at = scheduler.delivery_at_timezone.strftime('%a %d %b %Y-%H:%M:%S')
          #LABEL MAKER COMMENTED OUT FOR TIME BEING
          # orders = Order.order_summary(scheduler, false, 0, 0, restaurant_address_id.to_i)
          # csv = CSV.open(Rails.root.join('app/assets/csvs/file.csv'), "wb") do |csv|
          #   EmailLog.populate_csv(scheduler, orders, csv)
          # end
          # request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
          # response = request.execute
          # save_path = Rails.root.join('public','summary',"#{response.body.split("/")[1]}")
          # File.open(save_path, 'wb') do |file|
          #   file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
          # end
          # File.open("#{Rails.root}/public/summary/#{response.body.split("/")[1]}", 'r') do |f|
          #   send_data f.read, filename: "Chowmill-Labels-Order-#{scheduler.id}.docx"
          # end
          # File.delete(save_path) if File.exist?(save_path)
        end
      end
    else
      render json: {message: "No orders yet"}, status: 403
    end
  end

  def orders_status
    if params[:token].present?
      address_runningmenu = AddressesRunningmenu.find_by(token: params[:token])
    else
      address_runningmenu = AddressesRunningmenu.find_by(runningmenu_id: params[:meeting_id], address_id: params[:id])
    end
    if address_runningmenu.present?
      if params[:type].present?
        params[:type] == 'accept' ? address_runningmenu.update_attributes(accept_orders: :acknowledge, message: params[:message]) : address_runningmenu.update_attributes(rejected_by_vendor: true, reject_reason: params[:message])
      else
        address_runningmenu.orders_acknowledge!
      end
      render json: {message: "success"}
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def acknowledge_schedule
    if params[:token].present?
      runningmenuaddress = AddressesRunningmenu.find_by(token: params[:token])
    else
      runningmenuaddress = AddressesRunningmenu.find_by(address_id: current_member.address_id, runningmenu_id: params[:id])
    end
    if runningmenuaddress.present?
      if runningmenuaddress.orders_acknowledge? || runningmenuaddress.changes_acknowledge?
        @orders = runningmenuaddress.runningmenu.orders.active
      else
        if params[:type] == 'ack_schedule' && runningmenuaddress.receipt_acknowledge!
          render json: {success: "true"}
        elsif params[:type] == 'accept_orders' && runningmenuaddress.orders_acknowledge!
          render json: {success: "true"}
        elsif params[:type] == 'accept_changes' && runningmenuaddress.changes_acknowledge!
          render json: {success: "true"}
        else
          render json: {success: "false"}
        end
      end
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def zendesk_support
    begin
      api_ticket = ZendeskAPI::Ticket.create!($zendesk_client,
        # :custom_fields => {:id=> ENV["ZENDESK_CUSTOM_EMAIL_ID"], :value => params[:email]},
        :requester => {:email => params[:email], :name=>current_member.name},
        :subject => params[:subject],
        :description => params[:description],
        :external_id => current_member.id)
      @freshdesklogs = FreshDeskLog.where(:requester=>current_member.id.to_s, :widget_type=>FreshDeskLog.widget_types.keys[0])
    rescue => e
      render :json=>{message: e.message}, status: 406
    end
  end

  def cuisines
    @cuisines = Cuisine.active.all
  end

  private

  def restaurant_addressable_params
    params.require(:addressable).permit(:name, cuisine_ids: [])
  end

  def restaurant_admin_params
    if params[:user][:password].blank?
      params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :send_text_reminders, :fax, :fax_summary_check, :email_label_check, :email_summary_check, :status)
    else
      params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :password, :send_text_reminders, :fax, :fax_summary_check, :email_label_check, :email_summary_check, :status)
    end
  end

  def restaurant_params
    params.require(:restaurant).permit(
      :address_name,
      :address_line,
      :address_ids,
      :restaurant_address_ids,
      :time_zone,
      :suite_no,
      :street_number,
      :street,
      :city,
      :state,
      :zip,
      :longitude,
      :latitude,
      :status,
      :delivery_radius,
      :delivery_cost,
      :individual_meals_cutoff,
      :buffet_cutoff,
      :logo,
      images_attributes: [
        :id,
        :_destroy,
        :image
      ],
      contacts_attributes: [
        :id,
        :_destroy,
        :name,
        :phone_number,
        :send_text_reminders,
        :email,
        :fax,
        :email_label_check,
        :fax_summary_check,
        :email_summary_check
      ],
      monday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      tuesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      wednesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      thursday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      friday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      saturday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ],
      sunday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :_destroy
      ]
    )
  end

  def set_restaurant
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["id"].to_i) rescue nil
    if authorized_current_member.present?
      @restaurant = RestaurantAddress.find(params[:id])
      if params[:menu_type].present?
        case params[:menu_type]
        when "lunch"
          if @restaurant.menu_lunch.present?
            if MenuLunch.exists?(draft_id: @restaurant.menu_lunch.id)
              @lunchMenu = MenuLunch.find_by(draft_id: @restaurant.menu_lunch.id)
            end
          else
            render json: {message: "No menu present"}
          end
        when "dinner"
          if @restaurant.menu_dinner.present?
            if MenuDinner.exists?(draft_id: @restaurant.menu_dinner.id)
              @dinnerMenu = MenuDinner.find_by(draft_id: @restaurant.menu_dinner.id)
            end
          else
            render json: {message: "No menu present"}
          end
        when "buffet"
          if @restaurant.menu_buffet.present?
            if MenuBuffet.exists?(draft_id: @restaurant.menu_buffet.id)
              @buffetMenu = MenuBuffet.find_by(draft_id: @restaurant.menu_buffet.id)
            end
          else
            render json: {message: "No menu present"}
          end
        else
          if @restaurant.menu_breakfast.present?
            if MenuBreakfast.exists?(draft_id: @restaurant.menu_breakfast.id)
              @breakfastMenu = MenuBreakfast.find_by(draft_id: @restaurant.menu_breakfast.id)
            end
          else
            render json: {message: "No menu present"}
          end
        end
      end
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def validate_admin
    if !(current_member.restaurant_admin? && current_member.addresses.exists?(params[:id]) && Runningmenu.exists?(params[:meeting_id]) && Runningmenu.find(params[:meeting_id]).addresses.exists?(params[:id]))
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  def set_runningmenu
    @runningmenu = Runningmenu.find_by_id params[:meeting_id]
    if @runningmenu.blank?
      render json: {message: "Meeting does not exist"}
    end
  end

  def total_orders
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id) rescue nil
    if authorized_current_member.present?
      @address_ids = current_member.addresses_vendor.pluck(:address_id).join(',')
      @orders_today = []
      @orders = []
      @start_of_week = Time.current.in_time_zone(current_member.time_zone).beginning_of_day.utc.to_s(:db)
      @end_of_week =  (Time.current+4.days).in_time_zone(current_member.time_zone).at_end_of_day.utc.to_s(:db)
      @orders_today = Runningmenu.connection.select_all("SELECT DISTINCT DATE(runningmenus.pickup_at AT TIME ZONE companies.time_zone) AS pickup_at, count(DISTINCT runningmenus.id) AS orders_count, SUM(orders.quantity) AS items_count from runningmenus INNER JOIN addresses_runningmenus ON addresses_runningmenus.runningmenu_id = runningmenus.id INNER JOIN companies ON companies.id = runningmenus.company_id INNER JOIN addresses ON addresses.id = addresses_runningmenus.address_id  INNER JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.restaurant_address_id = addresses.id where addresses.addressable_type = 'Restaurant' AND runningmenus.status=0 AND orders.status = 0 AND addresses_runningmenus.address_id IN (#{@address_ids})  AND runningmenus.pickup_at BETWEEN '#{@start_of_week}' AND '#{@end_of_week}' GROUP BY DATE(runningmenus.pickup_at AT TIME ZONE companies.time_zone)").to_hash
      dates = (Time.current.in_time_zone(current_member.time_zone).beginning_of_day.to_date.. (Time.current+4.days).in_time_zone(current_member.time_zone).at_end_of_day.to_date).to_a
      for i in 0...5 do
        @orders[i] ={"pickup_at" => dates[i], "total_orders" => 0, "total_items" => 0}
      end
      @orders.each_with_index do |order, indx|
        @orders_today.each do |o|
          if o["pickup_at"].to_date == order["pickup_at"]
            @orders[indx]["total_orders"] += o["orders_count"].to_i
            @orders[indx]["total_items"] += o["items_count"].to_i
          end
        end
      end
    else
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
    @orders
  end

end
