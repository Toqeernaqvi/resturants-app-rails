# app/controllers/api/v1/addresses_controller.rb
class Api::V1::AddressesController < Api::V1::ApiController
  before_action :set_address

  def menus
    if @address.blank?
      error(E_INTERNAL, 'No restaurant address defined')
    else
      p_params = "p_s3_base_url := 'https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com'::TEXT, p_address_id := #{@address.id}, p_company_id := #{current_member.company_id}, p_menu_type := #{params[:menu_type]}, p_current_user_id := #{current_member.id} "
      if params[:r].present?
        p_r = params[:r].join(",")
        p_params += ", p_r:= '#{p_r}'"
      end
      if params[:d].present?
        p_d = params[:d].join(",")
        p_params += ", p_d:= '#{p_d}'"
      end
      if params[:i].present?
        p_i = params[:i].join(",")
        p_params += ", p_i:= '#{p_i}'"
      end
      sql = "SELECT * FROM address_menus(#{p_params})"
      menus = ActiveRecord::Base.connection.execute(sql)
      render json: FetchMenus.call(current_member, menus.first["address_menus"])
    end
  end

  private

  def set_address
    @address = RestaurantAddress.find_by_id params[:address_id]
  end
end