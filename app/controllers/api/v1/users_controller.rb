# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::ApiController
  before_action :check_ability, only: [:index]
  before_action :set_user, only: [:update]
  # GET /users
  def index
    sort_order = params[:sort_order].present? ? params[:sort_order] : "ASC"
    if params[:sort_type].present?
      order = "CASE WHEN users.confirmed_at IS NUll THEN 1 ELSE 0 END #{sort_order}" if params[:sort_type] == "status"
      order = "LOWER(users.first_name) #{sort_order}, LOWER(users.last_name) #{sort_order}" if params[:sort_type] == "name"
      order = "users.last_sign_in_at #{sort_order}" if params[:sort_type] == "login"
      sort_type = params[:sort_type]
    else
      sort_type = "name"
      order = "LOWER(users.first_name) ASC, LOWER(users.last_name) ASC"
    end
    where_str = search
    @sort_order = sort_order
    @sort_type = sort_type
    @per_page = 50
    @count = current_member.company.staffs.where(where_str).order(order).count
    @users = current_member.company.staffs.where(where_str).order(order).page(params[:page]).per(@per_page)
    #commented code for future reference if needed.
    # sort_order = params[:sort_order].present? ? params[:sort_order] : "ASC"
    # if params[:sort_type].present?
    #   order = "CASE WHEN users.confirmed_at IS NUll THEN 1 ELSE 0 END #{sort_order}" if params[:sort_type] == "status"
    #   order = "LOWER(users.first_name) #{sort_order}, LOWER(users.last_name) #{sort_order}" if params[:sort_type] == "name"
    #   order = "users.last_sign_in_at #{sort_order}" if params[:sort_type] == "login"
    #   sort_type = params[:sort_type]
    # else
    #   sort_type = "name"
    #   order = "LOWER(users.first_name) ASC, LOWER(users.last_name) ASC"
    # end
    # @sort_order = sort_order
    # @sort_type = sort_type
    # @per_page = 50
    # @count = current_member.company.staffs.active.order(order).count
    # @users = current_member.company.staffs.active.order(order).page(params[:page]).per(@per_page)
  end

  def search
    query = "true"
    return query if params.blank?
    user_types = params[:user_types].join(',') if params[:user_types].present?
    unless params["query"].blank?
      params["query"].split(",").each do |word|
        query += " AND (first_name ILIKE '%#{word}%' OR last_name ILIKE '%#{word}%' OR email ILIKE '%#{word}%')"
      end
    end
    if params[:user_types].present?
      query += " AND user_type IN (#{user_types})"
    end
    if params["status"].present?
      query += " AND status = '#{params["status"].to_i}'"
    end
    if params["invited_user"].present? && params["invited_user"]== "true"
      query += " AND confirmed_at IS NOT NULL"
    end
    query
    #commented code for future reference if needed.
    # query = "true"
    # params["query"].split(",").each do |word|
    #   query += " AND (first_name ILIKE '%#{word}%' OR last_name ILIKE '%#{word}%' OR email ILIKE '%#{word}%')"
    # end
    # @users = current_member.company.staffs.active.where(query)
    # @users = current_member.company.staffs.where(query)
  end

  def update
    if @user.update(user_params)
      render json: {
        success: true,
        message: "User has been updated successfully."
      }, status: 200
    else
      error(E_INTERNAL, @user.errors.full_messages)
    end
  end

  # DESTROY /users
  def destroy
    begin
      user = User.find(params[:id])
      user.parent_status_deleted!
      user.deleted!
      render json: {message: 'User deleted successfully'}
    rescue *RecoverableExceptions => e
      error(E_INTERNAL, 'Not deleted')
    end
  end

  # POST /users/send_invite
  def send_invite
    begin
      User.find(params[:id]).send_confirmation_instructions
      render json: {message: 'Invitation sent successfully'}
    rescue *RecoverableExceptions => e
      error(E_INTERNAL, "Couldn't able to send invitation")
    end
  end

  # GET /users/profile
  # PUT /users/profile
  def profile
    begin
      if request.put?
        if user_params[:stripe_token]&.empty?
          render :json => {message: "Invalid Token", user: current_member}
        elsif current_member.restaurant_admin?
          unless current_member.update_attributes(first_name: user_params[:first_name], last_name: user_params[:last_name], password: user_params[:password], profile_completed: User.profile_completeds[:yes])
            error(E_INTERNAL, current_member.errors.full_messages[0])
          end
          render :json => {message: "Vendor profile successfully updated", user: current_member}
        else
          unless current_member.update_attributes(user_params)
            error(E_INTERNAL, current_member.errors.full_messages[0])
          end
        end
      end
    rescue *RecoverableExceptions => e
      error(E_INTERNAL, current_member.errors.full_messages[0] || e.message)
    end
  end

  def invite
    if request.put?
      params[:emails].each do |data|
        e, f, l = data.split("\t")
        CompanyUser.create(company: current_member.company, time_zone: current_member.company.time_zone, office_admin: current_member, email: e, first_name: f, last_name: l)
      end
      render json: {message: 'Users created successfully'}
    else
      csv = CSV.parse(params[:emails])
      emails_invalid = []
      emails_exists = []
      emails = []
      csv.each do |row|
        e, f, l = row[0].split("\t")
        if e.match(URI::MailTo::EMAIL_REGEXP).present?
          if User.find_by_email(e).present?
            emails_exists << {email: e, first_name: f, last_name: l}
          else
            emails << {email: e, first_name: f, last_name: l}
          end
        else
          emails_invalid << {email: e, first_name: f, last_name: l}
        end
      end
      render json: {emails: emails, emails_invalid: emails_invalid, emails_exists: emails_exists}
    end
  end

  def send_vendor_invite
    if params[:vendor_name].present? && params[:vendor_address].present?
      email = ReferralsMailer.send_vendor_invite(current_member, params[:vendor_name], params[:vendor_address])
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      render json: {message: "Invitation sent successfully"}
    else
      render json: {message: "couldn't send invitation some parameters are missing"}
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    if @user.blank?
     render json: {
      success: false,
      message: 'User not found'
     }
    end
  end

  def check_ability
    if current_member.company_user? || current_member.unsubsidized_user? || current_member.company_manager? || !current_member.allow_admin_to_manage_users
      error(406, 'You are not allowed to manage users.')
    end
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :user_type,
      :time_zone,
      :address_id,
      :password,
      :stripe_token,
      :delete_stripe_card,
      :customer_id,
      :address_id,
      :survey_mail,
      :phone_number,
      :sms_notification,
      :cutoff_hour_lunch_reminder,
      :admin_cutoff_hour_lunch_reminder,
      :cutoff_hour_dinner_reminder,
      :admin_cutoff_hour_dinner_reminder,
      :cutoff_hour_breakfast_reminder,
      :admin_cutoff_hour_breakfast_reminder,
      :cutoff_day_lunch_reminder,
      :admin_cutoff_day_lunch_reminder,
      :cutoff_day_dinner_reminder,
      :admin_cutoff_day_dinner_reminder,
      :cutoff_day_breakfast_reminder,
      :admin_cutoff_day_breakfast_reminder,
      :menu_ready_email,
      cuisines_users_attributes: [:id, :_destroy, :cuisine_id],
      dietaries_users_attributes: [:id, :_destroy, :dietary_id],
      tag_list: [],
    ).merge(profile_completed: User.profile_completeds[:yes])
  end
end
