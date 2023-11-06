class Api::V1::UserRequestsController < ActionController::Base
  
  before_action :set_user, only: [:send_invite]
  before_action :check_user_exists, only: [:create]
  
  def send_invite
    if @user.invite_user(params[:admin_id].to_i)
      render json: {success: true, message: 'Invitation sent successfully'}
    else
      render json: {success: false, message: 'Invitation not sent due to some errors'}
    end
  end

  def create
    userrequest = UserRequest.new(user_request_params)
    if userrequest.save
      message = userrequest.invited_user ? 'Please check your email address for a registration link.' : 'An Email has been sent to your admin. You will receive a confirmation email when your admin confirms you.'
      render json: {success: true, message: message }
    else
      render json: {success: false, message: userrequest.errors.full_messages[0]}
    end
  end

  def set_user
    @user = UserRequest.where("id = ? AND responded = ? AND created_at > ?", params[:id], false, Time.current - 1.month).last
    if @user.nil?
      return render :json => {success: false, message: "Invalid user or already responded"}
    else
      @user.update_columns(responded: true)
    end
  end

  def check_user_exists
    if User.where(email: user_request_params[:email]).exists?
      user = User.where(email: user_request_params[:email]).last
      if user.active? && user.confirmed?
        return render json: {success: false, message: 'You already have an active account. Please click Forgot Password if you need assistance logging in.'}
      elsif user.active?
        user.force_mail_confirmation
        return render json: {success: false, message: 'Please check your email for a signup link.'}
      end
    end
  end

  private
  def user_request_params
    params.require(:user_request).permit(
      :first_name,
      :last_name,
      :email
    )
  end

end
