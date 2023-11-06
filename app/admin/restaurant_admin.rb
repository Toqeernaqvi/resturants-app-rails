ActiveAdmin.register RestaurantAdmin do
  menu false
  config.batch_actions = false
  actions :index, :create, :new, :edit, :update

  permit_params do
    if params[:restaurant_admin] && !params[:restaurant_admin][:password].blank?
      permitted = [:first_name, :last_name, :email, :password, :time_zone, :phone_number, :fax, :fax_summary_check, :email_summary_check, :email_label_check, :send_text_reminders, :primary_contact, address_ids: []]
    else
      permitted = [:first_name, :last_name, :email, :phone_number, :time_zone, :fax, :fax_summary_check, :email_summary_check, :email_label_check, :send_text_reminders, :primary_contact, address_ids: []]
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :password, label: "Reset Password", required: false unless f.object.new_record?
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :address_ids, as: :tags, label: "Restaurants", collection: RestaurantAddress.active.joins(:restaurant).select("CONCAT(restaurants.name,': ', addresses.address_line) as address_name, addresses.id, addresses.addressable_type, addresses.addressable_id, addresses.address_line")
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
      f.input :fax
      f.input :fax_summary_check, label: "Automatically Fax Order Summary", as: :boolean
      f.input :email_summary_check, label: "Automatically Send Order Summary", as: :boolean
      f.input :email_label_check, label: "Automatically Send Labels", as: :boolean
      f.input :send_text_reminders, as: :boolean
      f.input :primary_contact
      
      #Restaurant.joins(:addresses).select("CONCAT(restaurants.name,': ',addresses.address_line) as name, addresses.id")
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
  end
end
