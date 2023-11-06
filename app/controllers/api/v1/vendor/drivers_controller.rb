class Api::V1::Vendor::DriversController < Api::V1::Vendor::ApiController
  before_action :set_restaurant, only: [:index, :create]
  before_action :set_driver, only: [:show, :update]
  
  def index
    if params[:runningmenu_id].present?
      runningmenu = Runningmenu.find(params[:runningmenu_id])
      delivery_type = runningmenu.delivery_type
      delivery_at = runningmenu.delivery_at
      # pickup_time = delivery_at - 1.hour - 15.minutes
      pickup_time = runningmenu.pickup_at
      delivery_day, pickup_day = delivery_at.strftime("%A"), pickup_time.strftime("%A")
      p_params = "p_delivery_at := '#{delivery_at}', p_delivery_day := '#{delivery_day}', p_pickup_time := '#{pickup_time}', p_pickup_day := '#{pickup_day}', p_delivery_type := '#{delivery_type}', p_vendor := TRUE"
      if delivery_type == 'delivery'
        p_params += ", p_address_ids := '#{@restaurant_address.id}'"
      end
      drivers = DriverShift.find_by_sql("SELECT * FROM sp_drivers_list(#{p_params})")
      render json: {drivers: drivers}
    else
      @drivers = @restaurant_address.drivers.active.order("LOWER(drivers.first_name) ASC, LOWER(drivers.last_name) ASC")
    end
  end

  def show
  end

  def create
    @driver = @restaurant_address.drivers.new(driver_params.merge(created_from_frontend: true))
    if @driver.save
      render :show
    else
      error(E_INTERNAL, @driver.errors.full_messages[0])
    end
  end

  def update
    if @driver.update(driver_params.merge(updated_from_frontend: true))
      render :show
    else
      error(E_INTERNAL, @driver.errors.full_messages[0])
    end
  end

  def meeting_driver
    if params[:meeting_id].present? and params[:driver_id].present?
      runningmenu = Runningmenu.find params[:meeting_id]
      runningmenu.update_columns(driver_id: params[:driver_id].to_i)
      render :json => {message: "Meeting's driver updated"}
    else
      render :json => {message: "Parameter is missing"}, status: 404
    end
  end
  
  private

  def set_driver
    @driver = Driver.find(params[:id])
  end

  def set_restaurant
    @restaurant_address = RestaurantAddress.find params[:restaurant_id].to_i
    unless @restaurant_address.enable_self_service
      render :json => {status: 403, message: "Restaurant location's self service is not enabled"}, status: 403
    end
  end

  def driver_params
    params.require(:driver).permit(
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :car,
      :car_color,
      :car_licence_plate,
      :image,
      :status,
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

end
