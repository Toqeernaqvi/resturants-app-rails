ActiveAdmin.register AdminUser, as: 'Administrator' do
  menu false
  config.batch_actions = false
  actions :create, :new
  breadcrumb do
    if request.params[:action] == "new"
      [link_to('Admin', admin_users_path)]
    end
  end

  permit_params do
    permitted = [:first_name, :last_name, :email, :password, :user_type, :time_zone]
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :first_name
      f.input :last_name
      f.input :user_type, label: "Role", as: :select, collection: {"admin"=>0, "operations"=>4, "developer"=>5}.keys
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
    end
    f.actions do
      f.action :submit
      f.cancel_link admin_users_path
    end
  end
end
