ActiveAdmin.register UnsubsidizedUser, as: 'Unsubsidized User' do
  menu false
  config.batch_actions = false
  actions :index, :create, :new, :edit, :update

  permit_params do
    if params[:unsubsidized_user] && !params[:unsubsidized_user][:password].blank?
      permitted = [:first_name, :last_name, :tag_list, :user_type, :email, :password, :time_zone, :company_id, :address_id, :office_admin_id, :survey_mail, :cutoff_hour_lunch_reminder, :cutoff_hour_dinner_reminder, :cutoff_hour_breakfast_reminder, :cutoff_day_lunch_reminder, :cutoff_day_dinner_reminder, :cutoff_day_breakfast_reminder, :phone_number, :desk_phone, :sms_notification, :menu_ready_email]
    else
      permitted = [:first_name, :last_name, :tag_list, :user_type, :email, :time_zone, :company_id, :address_id, :office_admin_id, :survey_mail, :cutoff_hour_lunch_reminder, :cutoff_hour_dinner_reminder, :cutoff_hour_breakfast_reminder, :cutoff_day_lunch_reminder, :cutoff_day_dinner_reminder, :cutoff_day_breakfast_reminder, :phone_number, :desk_phone, :sms_notification, :menu_ready_email]
    end
  end

  form do |f|
    f.inputs do
      f.input :office_admin_id, as: :nested_select,
        level_1: {
          attribute: :comp_id,
          collection: Company.active.all,
          label: "Company Name"
        },
        level_2: {
          attribute: :office_admin_id,
          url: company_admins_admin_unsubsidized_users_path
        } if f.object.new_record?

      f.input :email if f.object.new_record?
      f.input :password, label: "Reset Password" , required: false unless f.object.new_record?
      f.input :first_name
      f.input :last_name
      f.input :user_type, as: :select, collection: ["company_admin", "company_user", "company_manager", "unsubsidized_user"].map{|a| [a.split("_").map(&:capitalize).join(" "), a]}, input_html: { class: 'user_type_combo'} unless f.object.new_record?
      f.input :tag_list, as: :tags, collection: ActsAsTaggableOn::Tag.for_tenant(f.object&.company_id).order(id: :asc).pluck(:name)
      f.input :address_id, as: :select, collection: f.object.company&.addresses&.active unless f.object.new_record?
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
      f.input :phone_number unless f.object.new_record?
      f.input :desk_phone, label: "Desk Phone" unless f.object.new_record?
      f.input :sms_notification, as: :boolean, label: "Text me when my food is delivered!" unless f.object.new_record?
      f.input :survey_mail, as: :boolean, label: "Receive emails to rate our food & service!"
      f.input :notification_label, as: :boolean, label: "Receive Reminder Emails One Hour Before Cutoff For"
      # f.inputs "Receive Reminder Emails One Hour Before Cutoff For" do
        f.input :cutoff_hour_breakfast_reminder, as: :boolean, label: "Breakfast"
        f.input :cutoff_hour_lunch_reminder, as: :boolean, label: "Lunch"
        f.input :cutoff_hour_dinner_reminder, as: :boolean, label: "Dinner"
      # end
      f.input :notification_label, as: :boolean, label: "Receive Reminder Emails 24 Hours Before Cutoff For"
      # f.inputs "Receive Reminder Emails 24 Hours Before Cutoff For" do
        f.input :cutoff_day_breakfast_reminder, as: :boolean, label: "Breakfast"
        f.input :cutoff_day_lunch_reminder, as: :boolean, label: "Lunch"
        f.input :cutoff_day_dinner_reminder, as: :boolean, label: "Dinner"
      # end
      f.input :menu_ready_email, as: :boolean, label: "Receive Notification Email When New Menu is Ready" unless f.object.new_record?
    end
    f.actions do
      f.action :submit
      f.cancel_link admin_users_path
    end
  end

  collection_action :company_admins, method: :get do
    admins = CompanyAdmin.active.where('company_id = ?', params[:q][:comp_id_eq])
    render json: admins.collect {|user| {:id => user.id, :name => user.name} }
  end

  controller do
    before_action :set_paper_trail_whodunnit
    
    def index
      redirect_to admin_users_path
    end

    def create
      params[:unsubsidized_user][:company_id] = params[:unsubsidized_user][:comp_id]
      params[:unsubsidized_user][:user_type] = "unsubsidized_user"
      super
    end

    def scoped_collection
      UnsubsidizedUser.unscoped
    end
  end
end
