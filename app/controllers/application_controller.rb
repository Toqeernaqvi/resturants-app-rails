class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, if: :verify_api
  before_action :clear_flash
  around_action :set_admin_timezone, if: :current_admin_user
  def clear_flash
    flash[:error].present? && !params[:controller] == "admin/menus" ? flash.clear : nil
  end

  def access_denied
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to admin_root_path, notice: "some thing wrong" }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end

  def verify_api
    params[:controller].split('/')[0] != 'devise_token_auth'
  end

  def authenticate_admin_user!
    if current_admin_user and current_admin_user.deleted?
    	sign_out current_admin_user
    	redirect_to new_admin_user_session_path, alert: "Invalid Email or password."
    else
    	super
    end
  end

  def set_admin_timezone
    Time.use_zone(current_admin_user.time_zone) { yield }
  end

  rescue_from Exception do |e|
    Airbrake.notify(e)
  end
end
