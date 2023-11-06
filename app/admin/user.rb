ActiveAdmin.register User, as: 'User' do
  menu priority: 7
  config.batch_actions = false
  actions :index, :show

  action_item :new, only: [:index] do
    link_to "Administrator", new_admin_administrator_path
  end

  action_item :new, only: [:index] do
    link_to "Add Company Administrator", new_admin_company_administrator_path
  end

  action_item :new, only: [:index] do
    link_to "Add Company User", new_admin_company_user_path
  end

  action_item :new, only: [:index] do
    link_to "Add Unsubsidized User", new_admin_unsubsidized_user_path
  end

  action_item :new, only: [:index] do
    link_to "Add Company Manager", new_admin_company_manager_path
  end

  action_item :new, only: [:index] do
    link_to "Add Restaurant Admin", new_admin_restaurant_admin_path
  end

  index do
    column :id
    column ("Company Name") {|u| u.company }
    column ("Office Admin") {|u| u.office_admin }
    column :first_name
    column :last_name
    column :email
    column "Last Login" do |u|
      u.last_sign_in_at&.strftime("%a. %b %d %-l:%M%P, %Y")
    end
    # column :time_zone
    column "Time Zone" do |u|
      ActiveSupport::TimeZone::MAPPING.select {|k, v| v == u.time_zone }.keys.first
    end
    column "User Type" do |u|
    #   if u.company_user? || u.company_admin?
    #     select :user_type, 'data-row-ID': "#{u.id}", class: "user_type_dropdown rowSelect#{u.id}", :collection => options_for_select(['Company Admin', 'Company User'].unshift(' '), u.company_admin? ? 'Company Admin' : 'Company User' )#, collection: User.user_types[:company_admin, :company_user]
    #   else
      u.user_type.split("_").map(&:capitalize).join(" ")
    #   end
    end
    column "Restaurant" do |user|
      if user.restaurant_admin?
        # user.addresses.first.addressable.name + ": " + user.addresses.first.address_line
        span do
          user.addresses.each do |address|
            span class: "user-index-restaurant-col" do
              address.addressable.name + ": " + address.address_line
            end
          end
        end
      end
    end
    column :status do |user|
      if user.active?
        status_tag( :active )
      else
        status_tag( :deleted )
      end
    end
    actions do |user|
      if user.company_admin?
        item('edit', edit_admin_company_administrator_path(id: user.id), class: :member_link)
      elsif user.company_user?
        item('edit', edit_admin_company_user_path(id: user.id), class: :member_link)
      elsif user.unsubsidized_user?
        item('edit', edit_admin_unsubsidized_user_path(id: user.id), class: :member_link)
      elsif user.company_manager?
        item('edit', edit_admin_company_manager_path(id: user.id), class: :member_link)
      elsif user.restaurant_admin?
        item('edit', edit_admin_restaurant_admin_path(id: user.id), class: :member_link)
        item('Resend Invite', resend_invite_restaurant_admin_user_path(id: user.id), method: :put, class: :member_link) if !user.confirmed? && user.profile_completed == "no"
      else
        item('edit', edit_admin_admin_role_path(id: user.id), class: :member_link)
      end
      if user.active?
        item('Delete', delete_admin_user_path(id: user.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_user_path(id: user.id), class: [:member_link, :active_btn])
      end
      if !user.admin? && !user.developer? && !user.operations? && user.active? && user.confirmed?
        item('Login to frontend', login_admin_user_path(id: user.id), target: "_blank", class: :member_link)
      end
    end
  end

  csv do
    column :id
    column ("Company Name") {|u| u.company.name if u.company.present? }
    column ("Office Admin") {|u| u.office_admin.name if u.office_admin.present? }
    column :first_name
    column :last_name
    column :email
    column "Time Zone" do |u|
      ActiveSupport::TimeZone::MAPPING.select {|k, v| v == u.time_zone }.keys.first
    end
  end

  show do
    attributes_table do
      row :id
      row :company
      row :first_name
      row :last_name
      row :email
      row "Last Login" do |user|
        user.last_sign_in_at&.strftime("%a. %b %d %-l:%M%P, %Y")
      end
      # row :time_zone
      row "Time Zone" do |user|
        ActiveSupport::TimeZone::MAPPING.select {|k, v| v == user.time_zone }.keys.first
      end
      row :status do |user|
        if user.active?
          status_tag( :active )
        else
          status_tag( :deleted )
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/user_model', locals: {versions: resource.versions.includes(:item)}
      end
    end
  end

  member_action :resend_invite_restaurant, method: :put do
    User.find(params[:id]).send_confirmation_instructions
    redirect_to admin_users_path, notice: 'Invite has been sent successfully!'
  end

  member_action :delete, method: :get do
    user = User.find(params[:id])
    if user.parent_status_active?
      user.parent_status_deleted!
      user.deleted!
      redirect_to admin_users_path, notice: "User has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    user = User.find(params[:id])
    if user.deleted?
      user.parent_status_active!
      user.active!
      redirect_to admin_users_path, notice: "User ha been successfully active"
    end
  end

  member_action :login, method: :get do
    user = User.find(params[:id])
    if user.present?
      user.frontend_login_token = rand(36**32).to_s(36)
      user.save
    end
    redirect_to  (user.restaurant_admin? ? ENV['VENDER_FRONTEND_HOST'] : ENV['FRONTEND_HOST']) + '/admin-login/' + user.frontend_login_token
  end

  collection_action :user_type, method: :post do
    if params[:uid].present? && params[:aid].present?
      user = User.find(params[:uid])
      user.user_type = 'company_user'
      user.office_admin_id = params[:aid]
      if user.save!
        render json: { message: 'Success'}
      else
        render json: { message: 'Fail'}
      end
    elsif params[:admin_id].present?
      user = User.find(params[:admin_id])
      user.user_type = 'company_admin'
      user.office_admin_id = nil
      if user.save!
        render json: { message: 'Success'}
      else
        render json: { message: 'Fail'}
      end
    end
  end

  collection_action :tags, method: :get do
    tags =  ActsAsTaggableOn::Tag.where("name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%").order(name: :asc).uniq
    render json: tags.collect {|tag| {:id => tag.id, :name => tag.name} }
  end

  collection_action :populate_office_admin, method: :get do
    respond_to do |format|
      format.js { render "populate_admin" }
    end
  end
  collection_action :office_admins, method: :get do
    office_admins =  User.active.where("first_name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
     render json: office_admins.collect {|office_admin| {:id => office_admin.id, :name => office_admin.name} }
  end
  collection_action :restaurants, method: :get do
    restaurants =  Restaurant.active.where("name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
     render json: restaurants.collect {|restaurant| {:id => restaurant.id, :name => restaurant.name} }
  end
  controller do
    skip_before_action :verify_authenticity_token, only: [:user_type]
  end
  filter :status_in, as: :select, label: "Status", collection: [["Active", User.statuses["active"]], ["Deleted", User.statuses["deleted"]],["Invited", "invited"]]
  filter :company_id, as: :search_select_filter, url: proc {  companies_admin_companies_path

 }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :company_id, label: 'Company', as: :select, collection: proc{ Company.active.all.pluck(:name, :id) }
  filter :office_admin_id, label: 'Office Admin', as: :search_select_filter, url: proc { office_admins_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :office_admin_id, label: 'Office Admin', as: :select, collection: proc{ User.active.map{ |u| [u.name, u.id] } }
  filter :email
  filter :first_name
  filter :last_name
  # filter :addresses_vendor_id, label: 'Restaurant Name', as: :search_select_filter, url: proc { restaurants_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :addresses_vendor_user_id, as: :select, collection: proc { RestaurantAdmin.active.pluck(:first_name, :id) }
  filter :addresses_vendor_id, input_html: {name: 'q[rest_in]'}, label: 'Restaurant Name', as: :search_select_filter, url: proc { restaurants_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px', method_model: User
  # filter :rest_in, label: "Restaurant Name", as: :select, collection: proc { Restaurant.active.pluck(:name, :id) }
  filter :user_type, label: 'Role Based', as: :select, collection: [["Admin", User.user_types["admin"]], ["Company Admin", User.user_types["company_admin"]], ["Company Manager", User.user_types["company_manager"]], ["Company User", User.user_types["company_user"]], ["Unsubsidized User", User.user_types["unsubsidized_user"]], ["Restaurant Admin", User.user_types["restaurant_admin"]], ["Operation", User.user_types["operations"]], ["Developer", User.user_types["developer"]]]
  filter :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
  filter :tags_id, as: :search_select_filter, url: proc {tags_admin_users_path },
  fields: [:name], display_name: 'name', minimum_input_length: 2, width: '233px', method_model: User

end
