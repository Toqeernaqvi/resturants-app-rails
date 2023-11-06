# frozen_string_literal: true

# see http://www.emilsoman.com/blog/2013/05/18/building-a-tested/
class Api::V1::Auth::SessionsController < :: DeviseTokenAuth::SessionsController
        protect_from_forgery with: :null_session

  skip_before_action :verify_authenticity_token, :only => :create
  before_action :set_user_by_token, only: [:destroy]
  after_action :reset_session, only: [:destroy]

  def create
    # Check
    field = (resource_params.keys.map(&:to_sym) & resource_class.authentication_keys).first

    @resource = nil
    if field
      q_value = get_case_insensitive_field_from_resource_params(field)

      @resource = find_resource(field, q_value)
    elsif params[:key].present?
      @resource = find_resource(:frontend_login_token, params[:key])
    end

    if @resource && ((params[:vendor] && @resource.user_type != "restaurant_admin") || (!params[:vendor] && (!["company_admin", "company_user", "unsubsidized_user", "company_manager"].include? @resource.user_type )) )
      render_create_error_bad_credentials
      return
    end

    if @resource && @resource.active? && valid_params?(field, q_value) && (!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
      valid_password = @resource.valid_password?(resource_params[:password])
      if (@resource.respond_to?(:valid_for_authentication?) && !@resource.valid_for_authentication? { valid_password }) || !valid_password
        return render_create_error_bad_credentials
      end
      @client_id, @token = @resource.create_token
      @resource.save

      sign_in(:user, @resource, store: false, bypass: false)

      yield @resource if block_given?

      render_create_success
    elsif @resource && @resource.active? && params[:key].present?
      @resource.frontend_login_token = nil
      @resource.save

      @client_id, @token = @resource.create_token
      @resource.save

      sign_in(@resource)

      yield @resource if block_given?

      render_create_success
    elsif @resource && !(!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
      if @resource.respond_to?(:locked_at) && @resource.locked_at
        render_create_error_account_locked
      else
        render_create_error_not_confirmed
      end
    else
      render_create_error_bad_credentials
    end
  end

  def render_create_success
    render "api/v1/auth/sign_in"
  end
end
