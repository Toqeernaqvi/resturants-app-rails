class Api::V1::Vendor::BillingsController < Api::V1::Vendor::ApiController
  before_action :set_restaurant


  def index
   time_zone = @restaurant.addressable.time_zone
    from = params[:orders_from].to_date.in_time_zone(time_zone).at_beginning_of_day
    to = params[:orders_to].to_date.in_time_zone(time_zone).at_end_of_day
    @count = @restaurant.restaurant_billings.where("orders_from >= ? AND orders_to <= ?", from, to).count
    @per_page = ENV['VENDOR_BILLINGS_PER_PAGE']
    if params[:sort_column].present? && params[:sort_direction].present?
      @billings = @restaurant.restaurant_billings.where("orders_from >= ? AND orders_to <= ?", from, to).order(params[:sort_column].to_sym => params[:sort_direction].to_sym).page(params[:page]).per(@per_page)
    else
      @billings = @restaurant.restaurant_billings.where("orders_from >= ? AND orders_to <= ?", from, to).order(billing_number: :desc).page(params[:page]).per(@per_page)
    end
  end

  def show
    @billing = @restaurant.restaurant_billings.find_by(address_id: params[:restaurant_id], id: params[:id])
    if @billing.present?
      q_params = "p_billing_id := #{@billing.id}, p_time_zone := '#{@restaurant.addressable.time_zone}'"
      if params[:sort_column].present? && params[:sort_direction].present?
        q_params += ", p_sort_column := '#{params[:sort_column]}', p_sort_direction := '#{params[:sort_direction]}'"
      end
      @orders = RestaurantBilling.find_by_sql("SELECT * from sp_billing_orders(#{q_params})")
    end
    unless @billing.present?
      render json: {message: "No record found."}
    end
  end

  private

  def set_restaurant
    authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["restaurant_id"].to_i) rescue nil
    if authorized_current_member.present?
      @restaurant = RestaurantAddress.find(params[:restaurant_id])
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
end
