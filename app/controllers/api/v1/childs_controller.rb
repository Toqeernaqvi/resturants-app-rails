class Api::V1::ChildsController < Api::V1::ApiController
  before_action :set_parent, only: [:index]
  before_action :set_company, only: [:show, :update, :company_admins, :company_locations]
  before_action :check_member

  #GET /childs
  def index
  end

  #GET childs/:id
  def show
    @bill = @company.billing
  end

  #POST /childs
  def create
    parent_company = current_member.company
    time_zone = child_params[:addresses_active_attributes].present? ? ActiveSupport::TimeZone::MAPPING.collect {|k, v| v}.include?(child_params[:addresses_active_attributes][0][:time_zone]) ? child_params[:addresses_active_attributes][0][:time_zone] : nil : nil
    @company = Company.new(child_params.merge(
      reduced_markup_check: parent_company.reduced_markup_check,
      user_copay: parent_company.user_copay,
      show_remaining_budget: parent_company.show_remaining_budget,
      enable_grouping_orders: parent_company.enable_grouping_orders,
      enable_saas: parent_company.enable_saas,
      markup: parent_company.markup,
      buffet_addons_markup: parent_company.buffet_addons_markup,
      parent_company_id: parent_company.id,
      time_zone: time_zone,
      remote_image_url: parent_company.image_url
      ))
    if @company.save
      email = CompanyMailer.child_created(@company)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      render :show
    else
      render json: {message: @company.errors.messages}, status: 422
    end
  end

  #PUT /childs/:id
  def update
    if @company.update(child_params)
      render json: {message: 'Company updated successfully'}
    else
      render json: {message: @company.errors.messages}, status: 422
    end
  end

  def update_user
    user = User.find user_params[:id]
    if user.update(user_params)
      render json: {message: 'Company updated successfully'}
    else
      render json: {message: @company.errors.messages}, status: 422
    end
  end

  #GET /childs/company_admins
  def company_admins
    @company_admins = User.where(:company_id =>@company.id, :status=>User.statuses[:active], :user_type=>User.user_types["company_admin"]).sort_by{|company_admin| company_admin.id == current_member.id ? 0 : 1}#.page(params[:page]).per(10)
  end

  #GET /childs/company_locations
  def company_locations
    @locations = @company.addresses_active#.page(params[:page]).per(10)
  end

  def set_parent
    @company = current_member.company
  end

  def set_company
    group_ids = current_member.company.parent_company_id.blank? ? [current_member.company_id]+current_member.company.childs.pluck(:id) : [current_member.company.parent_company_id]+current_member.company.parent_company.childs.pluck(:id)
    if group_ids.include?(params[:id].to_i)
      @company = Company.find(params[:id])
    else
      render json: {message: "Unauthorized access"}, status: 422
    end
  end

  def check_member
    if current_member.company_user? || current_member.company_manager? || current_member.unsubsidized_user?
      error(401, 'Company Users are not allowed')
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :id,
      :_destroy,
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :desk_phone,
      :status,
      :parent_status
    )
  end

  def child_params
    params.require(:company).permit(
      :name,
      :markup,
      :time_zone,
      :company_package,
      :user_meal_budget,
      :reduced_markup,
      :reduced_markup_check,
      :user_copay,
      :copay_amount,
      :show_remaining_budget,
      :image,
      :enable_grouping_orders,
      :site_survey,
      :delivery_notes,
      :buffet_addons_markup,
      :enable_marketplace,
      :enable_saas,
      :parent_company_id,
      location_ids: [],

      billing_attributes: [
        :id,
        :_destroy,
        :invoice_credit_card,
        :card_number,
        :expiry_year,
        :expiry_month,
        :cvc,
        :name,
        :weekly_invoice,
        :delivery_fee,
        :disable_auto_invoice,
        :change_card,
        :updated_from_backend,
        addresses_attributes: [
        :id,
        :_destroy,
        :address_line,
        :city,
        :state,
        :zip
      ],

      approvers_attributes: [
        :id,
        :_destroy,
        :name,
        :email,

        addresses_attributes: [
        :id,
        :_destroy,
        :address_line,
        :city,
        :state,
        :zip
      ],

      ],

      ],
      company_admins_active_attributes: [
        :id,
        :_destroy,
        :email,
        :first_name,
        :last_name,
        :phone_number,
        :desk_phone,
        :time_zone,
        :status,
        :parent_status
      ],
      addresses_active_attributes: [
        :id,
        # :_destroy,
        :address_line,
        :address_name,
        :short_code,
        :street_number,
        :street,
        :city,
        :state,
        :zip,
        :longitude,
        :latitude,
        :time_zone,
        :suite_no,
        :status,
        :parent_status,
        :user_id,
        :lunch_sequence_id,
        :dinner_sequence_id,
        :breakfast_sequence_id,
        :buffet_sequence_id,
        :delivery_instructions
      ],
      fields_active_attributes: [
        :id,
        :_destroy,
        :position,
        :field_type,
        :name,
        :status,
        :required,
        fieldoptions_attributes: [
          :id,
          :_destroy,
          :position,
          :name,
          :status,
        ]
      ]
    )
  end
end
