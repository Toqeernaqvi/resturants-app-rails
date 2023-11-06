# app/controllers/api/v1/reports_controller.rb
class Api::V1::ReportsController < Api::V1::ApiController

  #GET /reports
  def index
    payload = {
      :resource => {:dashboard => 7},
      :params => {
        "category" => current_member.company.name
      },
      :exp => Time.current.to_i + (60 * 10) # 10 minute expiration
    }
    token = JWT.encode payload, ENV["METABASE_SECRET_KEY"]

    iframe_url = ENV["METABASE_SITE_URL"] + "/embed/dashboard/" + token + "#bordered=true&titled=false"

    render json: {iframe_url: iframe_url}
  end
end