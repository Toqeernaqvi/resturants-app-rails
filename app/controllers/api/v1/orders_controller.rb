# app/controllers/api/v1/orders_controller.rb
class Api::V1::OrdersController < Api::V1::ApiController
  skip_before_action :authenticate_active_user, if: lambda { params[:token].present? }
  before_action :set_share_meeting, if: lambda { params[:token].present? }

  before_action :set_meeting, only: [:create]
  before_action :set_order, only: [:show, :cancel, :update]
  before_action :set_current_user_order, only: [:fooditem, :restaurant, :rating]
  before_action :set_buffet_runningmenu, only: [:buffet]

  # GET /orders/:id
  def show
    if params[:email] == 'email'
      email = OrderMailer.order_detail(current_member, @order)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      render json: {message: 'Email sent successfully'}
    else
      #
    end
  end

  # POST /rating
  def rating
    order = @user_order.last
    if current_member.company_admin? && params[:rating][:runningmenu_rating].present?
      meeting_rating = order.runningmenu.ratings.find_or_initialize_by(user_id: current_member.id, status: Rating.statuses[:active])
      meeting_rating.rating_value = params[:rating][:runningmenu_rating]
      meeting_rating.comment = params[:rating][:comment]
      meeting_rating.save
    else
      item_rating = order.fooditem.ratings.find_or_initialize_by(order_id: order.id, runningmenu_id: order.runningmenu_id, user_id: current_member.id, restaurant_address_id: order.restaurant_address_id, restaurant_id: order.restaurant_id, status: Rating.statuses[:active])
      item_rating.rating_value = params[:rating][:rating_value]
      item_rating.comment = params[:rating][:comment]
      item_rating.save
    end
    render json: {message: 'successfully rated'}
  end

  # GET /companies/orders/show
  # def company_orders_show
  #   if params[:runningmenu_id].present? && params[:address_id].present? && params[:order_type].present? && params[:ordered_at].present?
  #     @orders = Order.joins(:runningmenu).where(company_id: current_member.company_id)
  #       .where(runningmenu_id: params[:runningmenu_id])
  #       .where("runningmenus.address_id = ?", params[:address_id])
  #       .where("runningmenus.delivery_at BETWEEN ? AND ?", params[:ordered_at].to_date.in_time_zone(current_member.company.time_zone).at_beginning_of_day, params[:ordered_at].to_date.in_time_zone(current_member.company.time_zone).at_end_of_day)
  #       .where("runningmenus.runningmenu_type = ?", Runningmenu.runningmenu_types[params[:order_type]])
  #       .order('runningmenus.delivery_at DESC')

  #     @users = CompanyUser.active.where(company: current_member.company).where.not(id: Order.where(runningmenu_id: params[:runningmenu_id]).pluck('user_id').uniq)
  #     runningmenu = Runningmenu.find(params[:runningmenu_id])
  #     if params[:email] == 'email'
  #       if params[:users].blank?
  #         email = OrderMailer.company_order_detail(current_member, params[:ordered_at], @orders.active)
  #         EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #       elsif params[:users].present? && !runningmenu.hide_meeting
  #         users = User.where(id: params[:users])
  #         users.each do |user|
  #           email = OrderMailer.no_order_placed(user, runningmenu)
  #           EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #         end
  #       end
  #       render json: {message: 'Email sent successfully'}
  #     else
  #       #
  #     end
  #   end
  # end

  def buffet
    orders = Order.active.joins([:fooditem => :sections], :dishsize).where("orders.runningmenu_id = ?", @meeting.id).select("orders.*, fooditems.name, sections.section_type, dishsizes.serve_count")
    @grouped_orders = orders.group_by{|o| o.section_type }
  end

  # POST /schedules/:id/orders
  def create
    begin
      if current_member.present? && current_member.company_admin? && params[:order][:runningmenufields_attributes].present?
        fields_hash = {}
        params[:order][:runningmenufields_attributes].each_with_index do |rf, index|
          runningmenufield = Runningmenufield.find_by(runningmenu_id: @meeting.id, field_id: rf["id"])
          if runningmenufield.text?
            value = rf["value"].present? ? rf["value"] : ""
            fields_hash[index.to_s]={"field_id"=>runningmenufield.field_id, "value"=>value, "id"=>runningmenufield.id}
          else
            value = rf["value"].present? ? rf["value"].to_i : nil
            fields_hash[index.to_s]={"field_id"=>runningmenufield.field_id, "fieldoption_id"=>value, "id"=>runningmenufield.id}
          end
        end
        unless fields_hash.blank?
          runningmenu_obj = {"runningmenufields_attributes"=>fields_hash, "updated_from_frontend"=> true, user_at_update: current_member}
          unless @meeting.update(runningmenu_obj)
            error(E_INTERNAL, @meeting.errors.full_messages[0])
            return
          end
        end
      end
      if current_member.present? && current_member.company_admin? && @meeting.runningmenufields.joins(:field).where("fields.required = ? AND (CASE WHEN fields.field_type = 0 THEN runningmenufields.fieldoption_id IS NULL ELSE runningmenufields.value = ? END)", 1 , "").exists?
        error(E_INTERNAL, 'please add custom fields before order.')
      else
        @order = Order.new
        if current_member.present?
          @order = current_member.orders.new(
            order_params.merge(
              runningmenu_id: @meeting.id
            )
          )
        elsif @share_meeting.present?
          @order = Order.new(
            order_params.merge(
              runningmenu_id: @meeting.id,
              user_id: @share_meeting.user.id,
              share_meeting_id: @share_meeting.id
            )
          )
        end
        if @order.save
          render :show
        elsif params[:token].present? && @share_meeting.blank?
          error(E_INTERNAL, 'Meeting is not shared with this user')
        else
          error(E_INTERNAL, @order.errors.full_messages[0])
        end
      end
    rescue Stripe::StripeError => e
      error(E_INTERNAL, "Card charge failed due to #{e.message}")
    rescue => e
      error(E_INTERNAL, @order.errors.full_messages[0] || e.message)
    end
  end

  # PUT /schedules/:id/orders
  def update
    begin
      if @order.update(order_params)
        render :show
      else
        error(E_INTERNAL, @order.errors.full_messages[0])
      end
    rescue Stripe::StripeError => e
      error(E_INTERNAL, "Card charge failed due to #{e.message}")
    rescue => e
      error(E_INTERNAL, @order.errors.full_messages[0] || e.message)
    end
  end

  # PUT /schedules/:id/orders
  def cancel
    begin
      if @order.update(status: :cancelled, parent_status: :deleted, cancelled_time: Time.current)
        render json: {message: 'Order cancelled successfully'}
      else
        error(E_INTERNAL, @order.errors.full_messages[0])
      end
    rescue Stripe::StripeError => e
      error(E_INTERNAL, "Card charge failed due to #{e.message}")
    rescue => e
      error(E_INTERNAL, @order.errors.full_messages[0] || e.message)
    end
  end

  def order_ratings
    @data = Order.all.select('user_id, restaurant_id, rating')
  end

  def clone
    runningmenu = Runningmenu.friendly.find params[:runningmenu_id]
    if runningmenu.runningmenufields.joins(:field).where(fields: {required: 1, status: "active"}).select { |field| ( field.field_type == "text" && field.value.blank? ) || ( field.field_type == "dropdown" && field.fieldoption_id.nil? ) }.any?
      fields = []
      runningmenu.runningmenufields.joins(:field).where(fields: {status: "active"}).each do |rm_field|
        field_hash = rm_field.attributes
        field_hash["name"] = rm_field.field.name
        field_hash["required"] = rm_field.field.required
        field_hash["options"] = rm_field.field.fieldoptions.active.collect{|fo| {id: fo.id, name: fo.name}} if rm_field.dropdown?
        fields << field_hash
      end
      render json: fields
    else
      errors = Order.cloning(runningmenu, params[:order_ids], current_member.id)
      if errors.blank?
        result = Order.cloning_details(runningmenu, current_member)
        render json: {message: 'Order cloned successfully', runningmenu: {id: runningmenu.id,  total_quantity: result[0], avg_per_meal: result[1], order_total: result[2]}}
      else
        render json: {message: errors.first}, status: 403
      end
    end
  end

  private
  def order_params
    params.require(:order).permit(
      # :address_id,
      :fooditem_id,
      :quantity,
      :rating,
      :remarks,
      :stripe_token,
      :dishsize_id,
      optionsets_orders_attributes: [
        :id,
        :_destroy,
        :optionset_id,
        :required,
        options_orders_attributes: [
          :id,
          :_destroy,
          :option_id,
        ]
      ],
      orderfields_attributes: [
        :id,
        :_destroy,
        :field_id,
        :fieldoption_id,
        :value,
      ],
      guest_attributes: [
        :id,
        :first_name,
        :last_name,
        :email
      ]
    )
  end

  def set_order
    if params[:action].include? "show"
      @order = Order.includes(fooditem: [:dietaries, :ingredients, :dishsizes, optionsets: [options: [:dietaries, :ingredients]]]).find params[:id]
    else
      @order = Order.find params[:id]
    end
  end
  def set_meeting
    @meeting = Runningmenu.friendly.find params[:schedule_id]
    fooditem = Fooditem.find_by_id order_params[:fooditem_id]
    fooditem_tag_exists = fooditem.tags.where(id: @meeting.dynamic_sections.joins(:tags).pluck("tags.id").uniq).exists?
    error(E_INTERNAL, "Restaurant is not scheduled in this meeting") if !(fooditem.present? && (@meeting.addresses.active.include?(fooditem.menu.address) || fooditem_tag_exists))
  end
  def set_current_user_order
    #@user_order =  current_member.orders.active.find_by_id params[:id]
    @user_order = current_member.orders.active.joins(:runningmenu).where(id: params[:id]).where("runningmenus.delivery_at < ?", Time.current)
    if @user_order.blank?
      error(E_INTERNAL, 'No Such Record Found')
    end
  end
  def set_buffet_runningmenu
    # @meeting = Runningmenu.find_by(id: params[:schedule_id], menu_type: Runningmenu.menu_types[:buffet])
    @meeting = Runningmenu.buffet.find_by(slug: params[:schedule_id]) || Runningmenu.buffet.find_by(id: params[:schedule_id])
    if @meeting.blank?
      error(E_INTERNAL, 'No Such Record Found')
    end
  end
  def set_share_meeting
    @share_meeting = ShareMeeting.find_by(runningmenu_id: params[:schedule_id], token: params[:token])
  end
end
