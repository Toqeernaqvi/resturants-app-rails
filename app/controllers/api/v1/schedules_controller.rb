# app/controllers/api/v1/schedules_controller.rb
class Api::V1::SchedulesController < Api::V1::ApiController
  include FooditemHelper
  skip_before_action :authenticate_active_user, if: lambda { params[:token].present? }
  before_action :set_share_meeting, if: lambda { params[:token].present? }
  before_action :set_runningmenu, only: [:cancel, :update]
  before_action :check_member, only: [:cancel, :update]
  before_action :set_approved_runningmenu, only: [:orders, :notify_users, :recent]
  before_action :set_filters, only: [:delivery_dates]

  #GET /schedules
  # def index
  #   @runningmenus = Runningmenu.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(company_id: current_member.company.id)
  #   .order(id: :desc)
  # end
  #GET schedules/:id
  def show
    @runningmenu = @share_meeting.present? ? @share_meeting.runningmenu : Runningmenu.friendly.find_by("slug = ? AND company_id = ?", params[:id], current_member.company_id)
    tags_exists = false
    if @runningmenu.present? && !current_member&.company_admin? && @share_meeting.blank?
      tags_exist = ActiveRecord::Base.connection.exec_query("SELECT ((SELECT COUNT(*) < 1 FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = #{@runningmenu.id} AND taggings.taggable_type = 'Runningmenu') OR (SELECT (COUNT(*) > 0) FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = #{@runningmenu.id} AND taggings.taggable_type = 'Runningmenu' AND tags.id IN(SELECT tags.id FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = #{current_member.id} AND taggings.taggable_type = 'User'))) AS tags_exists")
      tags_exists = tags_exist.last["tags_exists"]
    end
    if (current_member&.company_admin? || @share_meeting.present?) ? @runningmenu.blank? : (@runningmenu.blank? || !tags_exists)
      error(406, 'No Such Record Found')
    end
  end

  #POST /schedules
  def create
    @runningmenu = Runningmenu.new(schedule_params.merge(
      user_id: current_member.id,
      status: :pending,
      activation_at: Time.current,
      per_user_copay: current_member.company.user_copay,
      per_user_copay_amount: current_member.company.copay_amount,
      delivery_type: current_member.company.enable_saas ? Runningmenu.delivery_types[:delivery] : Runningmenu.delivery_types[:pickup],
      created_from_frontend: true
      ))
    unless @runningmenu.addresses.blank?
      # @runningmenu.runningmenu_type = @runningmenu.meal_type
      # @runningmenu.per_meal_budget = current_member.company.user_meal_budget
      @runningmenu.hide_meeting = false
      # current_member.company.fields.each do |field|
      #   @runningmenu.runningmenufields.new(field_id: field.id)
      # end
    end
    if @runningmenu.save
      # render json: {message: 'Scheduler created successfully'}
      render :show
    else
      error(E_INTERNAL, @runningmenu.errors.full_messages[0])
    end
  end

  #PUT /schedules/:id
  def update
    if @runningmenu.update(schedule_params.merge(updated_from_frontend: true, user_at_update: current_member))
      @runningmenu.update_column(:deleted_cuisines, nil)
      if params[:order_ids].blank?
        render :show
      else
        errors = Order.cloning(@runningmenu, params[:order_ids], current_member.id)
        if errors.blank?
          result = Order.cloning_details(@runningmenu, current_member)
          render json: {message: 'Order cloned successfully', runningmenu: {id: @runningmenu.id, total_quantity: result[0], avg_per_meal: result[1], order_total: result[2]} }
        else
          render json: {message: errors.first}, status: 403
        end
      end
    else
      error(E_INTERNAL, @runningmenu.errors.full_messages[0])
    end
  end

  # GET /schedules/:id/notify_users
  def notify_users
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      @orders = Order.joins(:runningmenu, :restaurant, :user, :fooditem).where("orders.runningmenu_id = #{@runningmenu.id}").where(user_id: current_member.id)
    elsif current_member.company_admin?
      order_ids = Order.cancelled.joins(:runningmenu, :restaurant, :user, :fooditem).where("orders.runningmenu_id = #{@runningmenu.id} AND users.address_id != #{@runningmenu.address_id}").pluck(:id)
      @orders = Order.joins(:runningmenu, :restaurant, :user, :fooditem).where.not(:id=>order_ids).where("orders.runningmenu_id = #{@runningmenu.id}")
    end
    user_price = @orders.active.exists?(['user_price > ?', 0.0])
    email = OrderMailer.company_order_detail(current_member, @runningmenu, @orders.active, user_price)
    EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    render json: {message: 'Email sent successfully'}
  end

  def orders
    order_type = params[:sort_order].present? ? params[:sort_order] : "ASC"
    order_by = params[:sort_type].present? ? params[:sort_type] : "user"
    
    p_params = "p_company_id := #{@runningmenu.company_id}, p_address_id := #{@runningmenu.address_id}, p_runningmenu_id := #{@runningmenu.id}, p_backend_host := '#{ENV['BACKEND_HOST']}', p_order_by := '#{order_by}', p_order_type := '#{order_type}'"
    p_params += ", p_current_user_id := #{current_member.id}" if current_member.present? && @share_meeting.blank?
    p_params += ", p_share_meeting_id := #{@share_meeting.id}" if @share_meeting.present?
    sql = "SELECT * FROM sp_orders_detail(#{p_params})"
    result = ActiveRecord::Base.connection.exec_query(sql);
    result = result.first["sp_orders_detail"]
    result = JSON.parse(result)
    if result.present?
      result["orders"]&.map{|o| o["group"] = o["group"].split(",").map{|m| m.split("-")[0].scan(/\d+|[A-Za-z]+/)}.map{|x| x[0]+"-"+x[1]}.join(", ") if o["group"].present? }
    end
    render json: result
  end

  # DELETE /schedules/:id/cancel
  def cancel
    if @runningmenu.update(status: Runningmenu.statuses[:cancelled], parent_status: Runningmenu.parent_statuses[:deleted], cancel_reason: params[:cancel_reason], cancelled_by: current_member, cancelled_at: Time.current, stop_timezone_callback: true)
      # @runningmenu.orders.update_all(status: Order.statuses[:cancelled])
      render json: {message: 'Your meeting and its associated orders have been cancelled.'}
    else
      error(E_INTERNAL, @runningmenu.errors.full_messages[0])
    end
  end

  def recent
    filters = "orders.restaurant_address_id IN (#{@runningmenu.addresses.where(addresses_runningmenus: { dynamic_section_id: nil }).pluck(:id).join(',')})"
    filters += " AND orders.restaurant_id IN (#{params[:r].join(',')})" if params[:r].present?
    @orders = Order.find_by_sql("SELECT * FROM (SELECT DISTINCT ON(fooditem_id) orders.* FROM orders JOIN runningmenus ON runningmenus.id = orders.runningmenu_id JOIN restaurants ON orders.restaurant_id = restaurants.id JOIN fooditems ON fooditems.id = orders.fooditem_id WHERE runningmenus.status = #{Runningmenu.statuses[:approved]} AND runningmenus.delivery_at < '#{Time.current.to_s(:db)}' AND restaurants.name != '#{ENV['BEV_AND_MORE']}' AND fooditems.status = #{Fooditem.statuses[:active]} AND orders.user_id = #{current_member.id} AND orders.status = #{Order.statuses[:active]} AND #{filters}) AS t ORDER BY t.created_at DESC LIMIT 10")
  end

  #GET /checkrequests/:delivery_at/:type/:address_id
  # def checkrequests
  #   @runningmenus = Runningmenu.pending.where(delivery_at: params[:delivery_at].to_date.at_beginning_of_day..params[:delivery_at].to_date.at_end_of_day, runningmenu_type: params[:type], address_id: params[:address_id], company_id: current_member.company.id)
  #   render :index
  # end

  #GET /meetings
  # def meetings
  #   runningmenus = Runningmenu.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(delivery_at: schedule_params[:delivery_at]
  #   .to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day..schedule_params[:delivery_at]
  #   .to_date.in_time_zone(current_member.company.time_zone).at_end_of_day, status: current_member.company_admin? ? [:pending, :approved] : :approved)
  #   .where(company_id: current_member.company.id)
  #   runningmenuIds = runningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false ).pluck(:id)
  #   hideRunningmenus = runningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', true )
  #   if current_member.company_user? && hideRunningmenus.exists?
  #     shared_meetings = ShareMeeting.where(runningmenu_id: hideRunningmenus.pluck(:id)).where(email: current_member.email)
  #     shared_meetings.each do |sm|
  #       runningmenuIds.push(sm.runningmenu.id) if !runningmenuIds.include? sm.runningmenu.id && sm.runningmenu.delivery_at > Time.current && sm.runningmenu.cutoff_at > Time.current
  #     end
  #   end
  #   # @runningmenus = Runningmenu.where(id: runningmenuIds).order(current_member.company_user? ? 'DATE(cutoff_at) DESC' : 'DATE(admin_cutoff_at) DESC').order(delivery_at: :asc).select("*,CASE WHEN runningmenus.address_id = #{current_member.address_id} THEN 0 ELSE 1 END as current_member_addr").sort_by { |obj| obj.current_member_addr }
  #   @runningmenus = Runningmenu.where(id: runningmenuIds).order(delivery_at: :asc).select("*,CASE WHEN runningmenus.address_id = #{current_member.address_id} THEN 0 ELSE 1 END as current_member_addr").sort_by { |obj| obj.current_member_addr }
  # end

  #GET /delivery_dates

  def delivery_dates
    # runningmenusIds = []
    # if current_member.company_user?
    #   @runningmenus = Runningmenu.approved.joins(:address).joins("LEFT JOIN orders ON orders.runningmenu_id = runningmenus.id AND orders.user_id = #{current_member.id}").select("runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.company_id, runningmenus.delivery_at, runningmenus.hide_meeting, (CASE WHEN orders.user_id = #{current_member.id} AND orders.status = #{Order.statuses['active']} THEN true ELSE false END) placed_order").where('addresses.status = ?', Address.statuses[:active]).where(company_id: current_member.company.id).where(delivery_at: @from..@to).order(delivery_at: :asc).order('placed_order desc').uniq
    #   runningmenusIds = @runningmenus.reject{|r| r.hide_meeting == false }.pluck(:id)
    #   @runningmenus = @runningmenus.reject{|r| r.hide_meeting == true }
    # else
    #   @runningmenus=Runningmenu.approved.joins(:address).left_joins(:orders).select("runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.company_id, runningmenus.delivery_at, (CASE WHEN orders.status = #{Order.statuses['active']} AND orders.runningmenu_id IS NOT NULL THEN true ELSE false END) placed_order").where('addresses.status = ?', Address.statuses[:active]).where(company_id: current_member.company.id).where(delivery_at: @from..@to).order(delivery_at: :asc).order('placed_order desc').uniq
    # end
    # if current_member.company_user? && runningmenusIds.any?
    #   shared_meetings = Runningmenu.joins(:share_meetings).joins("LEFT JOIN orders ON orders.share_meeting_id = share_meetings.id").select("runningmenus.id, runningmenus.slug, runningmenus.runningmenu_type, runningmenus.company_id, runningmenus.delivery_at, (CASE WHEN orders.status = #{Order.statuses['active']} AND orders.share_meeting_id IS NOT NULL THEN true ELSE false END) placed_order").where(id: runningmenusIds.uniq, share_meetings: { email: current_member.email }).uniq
    #   shared_meetings.each do |meeting|
    #     @runningmenus.push(meeting) if meeting.delivery_at < Time.current && meeting.cutoff_at < Time.current
    #   end
    # end
    # runningmenus = {}
    # @runningmenus.group_by{|r| r.delivery_at_timezone&.to_date.to_s }.each do |delivery_at, meetings|
    #   runningmenus[delivery_at] = meetings&.collect{|r| {id: r.id, slug: r.slug, runningmenu_type: r.runningmenu_type, placed_order: r.placed_order } }
    # end
    # render json: runningmenus
    p_params = "p_from := '#{@from.utc.to_s(:db)}', p_to := '#{@to.utc.to_s(:db)}', p_company_id := #{current_member.company_id}, p_current_user_id := #{current_member.id}"
    meetings = DriverShift.find_by_sql("SELECT * FROM sp_delivery_dates(#{p_params})")
    runningmenus = {}
    if meetings.first["sp_delivery_dates"].present?
      meetings.first["sp_delivery_dates"].group_by{|r| r["delivery_at"].to_date.to_s }.each do |delivery_at, meetings|
        runningmenus[delivery_at] = meetings.uniq {|r| r["id"] }
      end
    end
    render json: runningmenus
  end

  # def delivery_dates
  #   @approvedrunningmenus=Runningmenu.approved.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(company_id: current_member.company.id)
  #   .where('delivery_at >= ?', Time.current)
  #   @approvedRunningmenuIds = @approvedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', true ).pluck(:id)
  #   @approvedrunningmenus = @approvedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false ).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")

  #   formated_array = @approvedrunningmenus.map{ |approvedrunningmenu| approvedrunningmenu.to_date }
  #   unless formated_array.include? Time.current.to_date
  #     @currentDateRunningmenus=Runningmenu.approved.joins(:address)
  #     .where('addresses.status = ?', Address.statuses[:active])
  #     .where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false )
  #     .where(company_id: current_member.company.id)
  #     .where(delivery_at: Time.current.in_time_zone(current_member.company.time_zone).beginning_of_day..Time.current.in_time_zone(current_member.company.time_zone).end_of_day)

  #     if @currentDateRunningmenus.present?
  #       @currentDateRunningmenus.each do |currentDateRunningmenu|
  #         # if current_member.company_admin? && currentDateRunningmenu.orders.active.exists?
  #         #   @approvedrunningmenus.push(currentDateRunningmenu.delivery_at)
  #         # elsif current_member.company_user? && (currentDateRunningmenu.orders.active.exists?(user_id: current_member.id) || (currentDateRunningmenu.orders.active.exists? && currentDateRunningmenu.buffet?))
  #         #   @approvedrunningmenus.push(currentDateRunningmenu.delivery_at)
  #         # end
  #         @approvedrunningmenus.push(currentDateRunningmenu.delivery_at)
  #         break
  #       end
  #     end
  #     @default_runningmenu = Runningmenu.approved.where(company_id: current_member.company.id).where('delivery_at >= ?', Time.current.in_time_zone(current_member.company.time_zone).at_beginning_of_day).order(:delivery_at).first
  #     if @default_runningmenu.nil?
  #       @default_runningmenu = Runningmenu.approved.where(company_id: current_member.company.id).where('delivery_at < ?', Time.current.in_time_zone(current_member.company.time_zone).at_beginning_of_day).order(:delivery_at).last
  #     end
  #   # else
  #   #   unless Runningmenu.joins(:orders).where("orders.status = ?", Order.statuses[:active]).where("runningmenus.delivery_at BETWEEN ? AND ?", Time.current.beginning_of_day, Time.current.end_of_day).where(current_member.company_user? ? "orders.user_id = ? OR runningmenus.menu_type = #{Runningmenu.menu_types[:buffet]}" : '', current_member.id).exists?
  #   #     @approvedrunningmenus.delete_at formated_array.index Time.current.to_date
  #   #   end
  #   end

  #   @pendingrunningmenus=Runningmenu.pending.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false )
  #   .where(company_id: current_member.company.id)
  #   .where('delivery_at >= ?', Time.current)
  #   .group("delivery_at")
  #   .order("delivery_at ASC")
  #   .pluck("delivery_at")
  #   @futureday_pending_runningmenus=Runningmenu.pending.joins(:address).where('addresses.status = ?', Address.statuses[:active]).where(company_id: current_member.company.id).where(cutoff_at: Time.current..Time.current+24.hours).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")
  #   @futureday_runningmenus=Runningmenu.approved.joins(:address).where('addresses.status = ?', Address.statuses[:active]).where(company_id: current_member.company.id).where(cutoff_at: Time.current..Time.current+24.hours).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")
  #   if current_member.company_user? && @approvedRunningmenuIds.any?
  #     shared_meetings = ShareMeeting.where(runningmenu_id: @approvedRunningmenuIds).where(email: current_member.email)
  #     shared_meetings.each do |sm|
  #       @approvedrunningmenus.push(sm.runningmenu.delivery_at) if !@approvedrunningmenus.include? sm.runningmenu.delivery_at && sm.runningmenu.delivery_at > Time.current && sm.runningmenu.cutoff_at > Time.current
  #     end
  #   end

  #   past_start_date = Time.current.beginning_of_month - 7.days
  #   past_end_date = Time.current.yesterday.end_of_day
  #   @pastapprovedrunningmenus=Runningmenu.approved.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(company_id: current_member.company.id)
  #   .where(delivery_at: past_start_date..past_end_date)

  #   @pastapprovedRunningmenuIds = @pastapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', true ).pluck(:id)
  #   @pastapprovedrunningmenus = @pastapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false ).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")
  #   if current_member.company_user? && @pastapprovedRunningmenuIds.any?
  #     shared_meetings = ShareMeeting.where(runningmenu_id: @pastapprovedRunningmenuIds).where(email: current_member.email)
  #     shared_meetings.each do |sm|
  #       @pastapprovedrunningmenus.push(sm.runningmenu.delivery_at) if !@pastapprovedrunningmenus.include? sm.runningmenu.delivery_at && sm.runningmenu.delivery_at < Time.current && sm.runningmenu.cutoff_at < Time.current
  #     end
  #   end
  #   @pastnotapprovedrunningmenus = (past_start_date.to_datetime..past_end_date.to_datetime).map(&:to_s) - @pastapprovedrunningmenus.map{|d| d.change({hour: 0, min: 0, sec: 0})}.map(&:to_datetime).map(&:to_s)
  #   # @pastnotapprovedrunningmenus=Runningmenu.joins(:address)
  #   # .where('runningmenus.status != ? AND addresses.status = ?', Runningmenu.statuses[:approved], Address.statuses[:active])
  #   # .where(company_id: current_member.company.id)
  #   # .where(delivery_at: past_start_date..past_end_date)

  #   # @pastnotapprovedRunningmenuIds = @pastnotapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', true ).pluck(:id)
  #   # @pastnotapprovedrunningmenus = @pastnotapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false ).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")
  #   # if current_member.company_user? && @pastnotapprovedRunningmenuIds.any?
  #   #   shared_meetings = ShareMeeting.where(runningmenu_id: @pastnotapprovedRunningmenuIds).where(email: current_member.email)
  #   #   shared_meetings.each do |sm|
  #   #     @pastnotapprovedrunningmenus.push(sm.runningmenu.delivery_at) if !@pastnotapprovedrunningmenus.include? sm.runningmenu.delivery_at && sm.runningmenu.delivery_at < Time.current && sm.runningmenu.cutoff_at < Time.current
  #   #   end
  #   # end
  #   if current_member.company_user?
  #     @greenapprovedrunningmenus=Runningmenu.approved.joins(:address, :orders).where('addresses.status = ?', Address.statuses[:active]).where("orders.status = ? AND orders.user_id = ?",Order.statuses["active"], current_member.id).where(company_id: current_member.company.id).where("DATE(delivery_at) >= ?", Time.current.beginning_of_month - 7.days)
  #   else
  #     @greenapprovedrunningmenus=Runningmenu.approved.joins(:address, :orders).where('addresses.status = ?', Address.statuses[:active]).where("orders.status = ?",Order.statuses["active"]).where(company_id: current_member.company.id).where("DATE(delivery_at) >= ?", Time.current.beginning_of_month - 7.days)
  #   end
  #   @greenapprovedRunningmenuIds = @greenapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', true ).pluck(:id)
  #   @greenapprovedrunningmenus = @greenapprovedrunningmenus.where(current_member.company_user? ? 'runningmenus.hide_meeting = ?' : '', false ).group("delivery_at").order("delivery_at ASC").pluck("delivery_at")
  #   if current_member.company_user? && @greenapprovedRunningmenuIds.any?
  #     shared_meetings = ShareMeeting.where(runningmenu_id: @greenapprovedRunningmenuIds.uniq).where(email: current_member.email)
  #     shared_meetings.each do |sm|
  #       @greenapprovedrunningmenus.push(sm.runningmenu.delivery_at) if !@greenapprovedrunningmenus.include? sm.runningmenu.delivery_at && sm.runningmenu.delivery_at < Time.current && sm.runningmenu.cutoff_at < Time.current
  #     end
  #   end
  # end

  #GET /menu_change_request/:delivery_at/:type/:address_id
  # def request_menu_change
  #   @runningmenus = Runningmenu.approved.joins(:address)
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(delivery_at: params[:delivery_at].to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day..params[:delivery_at].to_date.in_time_zone(current_member.company.time_zone).at_end_of_day, runningmenu_type: params[:type], address_id: params[:address_id], company_id: current_member.company.id)
  #   if @runningmenus.present?
  #     @runningmenus.first.addresses.destroy_all
  #     @runningmenus.first.pending!
  #     if @runningmenus.first.runningmenu_request.present?
  #       render :index
  #     else
  #       menu_request = RunningmenuRequest.create(
  #         runningmenu_request_type: @runningmenus.first.runningmenu_type,
  #         address_id: @runningmenus.first.address_id,
  #         company_id: @runningmenus.first.company_id,
  #         user_id: current_member.id,
  #         delivery_at: @runningmenus.first.delivery_at,
  #         orders: @runningmenus.first.orders_count,
  #         menu_type: @runningmenus.first.menu_type,
  #         special_request: @runningmenus.first.special_request,
  #         end_time: @runningmenus.first.delivery_at,
  #         schedular_check: true,
  #         cuisine_ids: @runningmenus.first.cuisines.pluck('id')
  #       )
  #       menu_request.save!
  #       @runningmenus.first.runningmenu_request_id = menu_request.id
  #       @runningmenus.first.save(validate: false)
  #       render :index
  #     end
  #   else
  #     render json: {message: 'No Schedular Exists'}
  #   end
  # end

  # def pendingrequests
  #   @runningmenus = Runningmenu.pending.joins(:address).select("runningmenus.id, runningmenus.runningmenu_type, runningmenus.address_id, runningmenus.delivery_at, TO_CHAR(runningmenus.delivery_at, 'YYYY-mm-dd') AS date, TO_CHAR(runningmenus.delivery_at, 'YYYY') AS year, TO_CHAR(runningmenus.delivery_at, 'mm') AS month, TO_CHAR(runningmenus.delivery_at, 'dd') AS day")
  #   .where('addresses.status = ?', Address.statuses[:active])
  #   .where(company_id: current_member.company.id)
  # end

  def set_runningmenu
    @runningmenu = Runningmenu.find_by(slug: params[:id], company_id: current_member.company_id)
    if @runningmenu.blank?
      error(406, 'No Such Record Found')
    end
  end

  def set_share_meeting
    @share_meeting = ShareMeeting.find_by(token: params[:token])
    unless @share_meeting.present?
      error(E_INTERNAL, 'Unable to find shared meeting')
    end
  end

  def check_member
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      error(401, "#{current_member.user_type.titleize}s are not allowed")
    end
  end

  def set_approved_runningmenu
    @runningmenu = @share_meeting.present? ? @share_meeting.runningmenu : Runningmenu.approved.find_by(slug: params[:id], company_id: current_member.company_id)
    if @runningmenu.blank?
      error(406, 'No Such Record Found')
    end
  end

  private
  def schedule_params
    params.require(:runningmenu).permit(
      :runningmenu_name,
      :runningmenu_type,
      :address_id,
      :delivery_at,
      :orders_count,
      :menu_type,
      :special_request,
      :schedular_check,
      :skip_cuttoff_check,
      :cutoff_at,
      :end_time,
      :admin_cutoff_at,
      :per_meal_budget,
      :cancel_reason,
      :marketplace,
      :delivery_instructions,
      cuisines_menus_attributes: [
        :id,
        :_destroy,
        :cuisine_id
      ],
      runningmenufields_attributes: [
        :id,
        :_destroy,
        :field_id,
        :fieldoption_id,
        :value
      ],
      address_ids:[]
    )
  end

  def set_filters
    @from = params[:from].blank? ? (Time.current-1.month).beginning_of_month : params[:from].to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day
    @to = params[:to].blank? ? (Time.current+1.month).end_of_month : params[:to].to_date.in_time_zone(current_member.company.time_zone).at_end_of_day
  end
end
