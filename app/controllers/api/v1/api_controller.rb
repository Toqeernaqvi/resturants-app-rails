class Api::V1::ApiController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  protect_from_forgery with: :null_session

  devise_token_auth_group :member, contains: [:company_admin, :company_user, :company_manager, :unsubsidized_user, :restaurant_admin]
  before_action :authenticate_active_user
  before_action :set_paper_trail_whodunnit

  around_action :set_time_zone, if: :current_member

  RecoverableExceptions = [
      ActiveRecord::RecordNotUnique,
      ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved
  ]

  HTTP_FAIL = 422
  HTTP_CRASH = 406
  HTTP_SUCCESS = 200

  STATUS_OK = 'ok'
  STATUS_ERROR = 'Error'
  E_INVALID_JSON = 1
  E_INVALID_SESSION = 2
  E_ACCESS_DENIED = 3
  E_INTERNAL = 4
  E_SIGNUP_FAILED = 5
  E_INVALID_LOGIN = 6
  E_RESOURCE_NOT_FOUND = 7
  E_INVALID_PARAM = 8
  E_API = 9
  E_METHOD_NOT_FOUND = 10
  E_UNSUPPORTED = 11

  VERSION = '1.0.0'

  DIRECTION = { up: 0, down: 1 }
  TIMESTAMP_TYPE = { updated_at: 0, created_at: 1 }
  LIMIT = 20

  rescue_from Exception do |e|
    error(E_API, "An internal API error occured. Please try again.\n #{e.message}")
    Airbrake.notify(e)
  end

  def error(code = E_INTERNAL, message = 'API Error')
    render json: {
      status: STATUS_ERROR,
      error_no: code,
      message: message
    }, :status => HTTP_CRASH
    Airbrake.notify(message)
  end

  def render_resource_failure(resource, resource_name)
    render :json => {
      status: FAIL_STATUS,
      resource_name.to_sym => resource,
      full_messages: resource.errors.full_messages
    }, status: HTTP_FAIL
    Airbrake.notify(resource.errors.full_messages)
  end

  def validate_json
    begin
      JSON.parse(request.raw_post).deep_symbolize_keys
    rescue JSON::ParserError
      error E_INVALID_JSON, 'Invalid JSON received'
      return
    end
  end

  # @param object - a Hash or an ActiveRecord instance
  def success(object = {})
    object = JSON.parse(object.to_json) unless object.instance_of?(Hash)
    render json: { status: STATUS_OK }.merge(object)
  end


  def authenticate_active_user
    authenticate_member!
    if current_member.present? && !current_member.active?
      render :json => {
        status: 401,
        message: 'Unauthorized'
      }, status: 401
    end
  end

  protected

  def user_for_paper_trail
    member_signed_in? ? current_member.try(:email) : 'Unknown user'
  end

  private

  def set_time_zone
    Time.use_zone(current_member.restaurant_admin? ? current_member.time_zone : current_member.company.time_zone) { yield }
  end
end
