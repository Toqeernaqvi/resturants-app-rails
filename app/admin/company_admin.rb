ActiveAdmin.register CompanyAdmin, as: 'Company Administrator' do
  menu false
  config.batch_actions = false
  actions :index, :create, :new, :edit, :update

  permit_params do
    if params[:company_admin] && !params[:company_admin][:password].blank?
      permitted = [:company_id, :first_name, :last_name, :tag_list, :email, :phone_number, :desk_phone, :user_type, :time_zone, :password, :office_admin_id, :allow_admin_to_manage_users, :sms_notification, :survey_mail, :admin_cutoff_hour_lunch_reminder, :admin_cutoff_hour_dinner_reminder, :admin_cutoff_hour_breakfast_reminder, :admin_cutoff_day_lunch_reminder, :admin_cutoff_day_dinner_reminder, :admin_cutoff_day_breakfast_reminder, :menu_ready_email, :disable_grouping_orders]
    else
      permitted = [:company_id, :first_name, :last_name, :tag_list, :email, :phone_number, :desk_phone, :user_type, :time_zone, :office_admin_id, :allow_admin_to_manage_users, :sms_notification, :survey_mail, :admin_cutoff_hour_lunch_reminder, :admin_cutoff_hour_dinner_reminder, :admin_cutoff_hour_breakfast_reminder, :admin_cutoff_day_lunch_reminder, :admin_cutoff_day_dinner_reminder, :admin_cutoff_day_breakfast_reminder, :menu_ready_email, :disable_grouping_orders]
    end
  end

  form do |f|
    f.inputs do
      f.input :company_id, label: 'Company Name', as: :select, :collection => Company.active.all.pluck(:name, :id) if f.object.new_record?
      f.input :email if f.object.new_record?
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :desk_phone, label: "Desk Phone"
      f.input :user_type, as: :select, 'data-row-ID': "#{resource.id}", class: "user_type_dropdown rowSelect#{resource.id}", collection: ["company_admin", "company_user", "company_manager", "unsubsidized_user"].map{|a| [a.split("_").map(&:capitalize).join(" "), a]} unless f.object.new_record?
      f.input :tag_list, as: :tags, collection: ActsAsTaggableOn::Tag.for_tenant(f.object&.company_id).order(id: :asc).pluck(:name)
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
      f.input :password, label: "Reset Password" , required: false unless f.object.new_record?
      f.input :office_admin_id, as: :select, :collection => resource.company.company_admins_active unless f.object.new_record?
      f.input :allow_admin_to_manage_users, as: :boolean
      f.input :disable_grouping_orders, as: :boolean, label: "Do not include orders in grouping"
      f.input :sms_notification, as: :boolean, label: "Text me when my food is delivered!"
      f.input :survey_mail, as: :boolean, label: "Receive emails to rate our food & service!"
      f.input :menu_ready_email, as: :boolean, label: "Receive Notification Email When New Menu is Ready"
      
      f.input :notification_label, as: :boolean, label: "Receive Reminder Emails One Hour Before Cutoff For"
      f.input :admin_cutoff_hour_breakfast_reminder, as: :boolean, label: "Breakfast"
      f.input :admin_cutoff_hour_lunch_reminder, as: :boolean, label: "Lunch"
      f.input :admin_cutoff_hour_dinner_reminder, as: :boolean, label: "Dinner"
      
      f.input :notification_label, as: :boolean, label: "Receive Reminder Emails 24 Hours Before Cutoff For"
      f.input :admin_cutoff_day_breakfast_reminder, as: :boolean, label: "Breakfast"
      f.input :admin_cutoff_day_lunch_reminder, as: :boolean, label: "Lunch"
      f.input :admin_cutoff_day_dinner_reminder, as: :boolean, label: "Dinner"
    end
    f.actions do
      f.action :submit
      f.cancel_link admin_users_path
    end
  end

  controller do
    def index
      redirect_to admin_users_path
    end
    def create
      params[:company_admin][:user_type] = "company_admin"
      super
      # binding.pry
    end

    def scoped_collection
      CompanyAdmin.unscoped
    end
  end
end
