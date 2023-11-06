class Api::V1::Vendor::ReportsController < Api::V1::Vendor::ApiController
    before_action :set_restaurant, only: [:index] #, :delivery_dates

    #GET /reports
    def index
      payload = {
        :resource => {:dashboard => 15},
        :params => {
          "restaurant" => @restaurant.addressable.name
        },
        :exp => Time.current.to_i + (60 * 10) # 10 minute expiration
      }
      token = JWT.encode payload, ENV["METABASE_SECRET_KEY"]
  
      iframe_url = ENV["METABASE_SITE_URL"] + "/embed/dashboard/" + token + "#bordered=true&titled=false"
  
      render json: {iframe_url: iframe_url}
    end

    def set_restaurant
        authorized_current_member = current_member.addresses_vendor.pluck(:address_id).include?(params["restaurant_id"].to_i) rescue nil
        if authorized_current_member.present?
          @restaurant = RestaurantAddress.find(params[:restaurant_id])
        else
            render :json => {
                status: 401,
                message: 'Unauthorized'
            }, status: 401
        end
    end
  end