# app/controllers/api/v1/announcements_controller.rb
class Api::V1::AnnouncementsController < Api::V1::ApiController
  devise_token_auth_group :member, contains: [:company_admin, :company_user, :company_manager, :restaurant_admin, :unsubsidized_user]
  #GET /announcements
  def index
    announcements = current_member.announcements.select(:id, :title, :description, :expiration).where("expiration > ?", Time.current)
    render json: announcements
  end
end
