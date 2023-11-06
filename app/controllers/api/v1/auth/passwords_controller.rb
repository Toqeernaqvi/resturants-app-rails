class Api::V1::Auth::PasswordsController < :: DeviseTokenAuth::PasswordsController
  protect_from_forgery with: :null_session
  require "base64"
  def create
    params[:email] = Base64.decode64(params[:email])
    user = User.find_by_email(params[:email]&.downcase)
    if user.present? && user.deleted?
      render json: {message: 'User is deleted'}
    elsif user.present? && (!user.confirmed? || user.profile_completed != "yes")
      user.send_confirmation_instructions
      render json: {success: true, message_heading: 'Account Verification Needed', message_text: 'In order to continue, please check your email for an account setup message from Chowmill.'}
    elsif !user.present?
      render json: {message: "Unable to find user with email '#{params[:email]}'"}
    else
      super
    end
  end

  def edit
    # if a user is not found, return nil
    @resource = with_reset_password_token(resource_params[:reset_password_token])

    if @resource && @resource.reset_password_period_valid?
      client_id, token = @resource.create_token

      # ensure that user is confirmed
      @resource.skip_confirmation! if confirmable_enabled? && !@resource.confirmed_at

      # allow user to change password once without current_password
      @resource.allow_password_change = true if recoverable_enabled?

      @resource.save!

      yield @resource if block_given?

      redirect_header_options = { reset_password: true }
      redirect_headers = build_redirect_headers(token,
                                                client_id,
                                                redirect_header_options)
      redirect_to(@resource.build_auth_url(params[:redirect_url],
                                           redirect_headers))
    else
      render "layouts/error_messages.html.erb"
    end
  end

  def update
     # make sure user is authorized
     return render_update_error_unauthorized unless @resource

     # make sure account doesn't use oauth2 provider
     unless @resource.provider == 'email'
       return render_update_error_password_not_required
     end

     # ensure that password params were sent
     unless password_resource_params[:password] && password_resource_params[:password_confirmation]
       return render_update_error_missing_password
     end

     if @resource.send(resource_update_method, password_resource_params)
       @resource.allow_password_change = false if recoverable_enabled?
       @resource.save!

       yield @resource if block_given?
       @resource.unlock_access! if unlockable?(resource)
       return render_update_success
     else
       return render_update_error
     end
  end

  private

  def with_reset_password_token token
    recoverable = resource_class.with_reset_password_token(token)

    # recoverable.reset_password_token = token if recoverable && recoverable.reset_password_token.present?
    recoverable
  end

  protected
  def unlockable?(resource)
    resource = @resource
    resource.respond_to?(:unlock_access!) &&
      resource.respond_to?(:unlock_strategy_enabled?) &&
      resource.unlock_strategy_enabled?(:email)
  end


end
