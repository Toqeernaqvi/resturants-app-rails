ActiveAdmin.register SmsLog, as: 'Sms Log' do
  #menu priority: 9
  menu parent: 'Logs'
  config.batch_actions = false
  actions :all, :except => [:new, :create, :destroy ]

  permit_params do
    permitted = [:from, :to, :body]
  end

  index do
    column :id
    column :name
    column :restaurant, sortable: ('restaurants.name')
    column :restaurant_address do |i|
      link_to i.restaurant_address.name, admin_restaurant_address_path(restaurant_id: i.restaurant_id, id: i.restaurant_address_id) if i.restaurant.present? && i.restaurant_address.present?
    end
    column :from
    column :to
    column :body
    column :failed_reason
    column :created_at { |sms| sms.created_at_timezone }
    column :status do |sms|
      status_tag( sms.status&.to_sym )
    end
    actions defaults: false do |sms_log|
      item 'View', admin_sms_log_path(sms_log), class: :member_link
      if sms_log.pending?
        item 'Edit', edit_admin_sms_log_path(sms_log), class: :member_link
        item('Cancel', cancel_admin_sms_log_path(sms_log.id), class: :member_link)
      end
    end
  end

  csv do
    column :id
    column :name
    column :restaurant
    column :restaurant_address
    column :from
    column :to
    column :body
    column :failed_reason
    column :created_at { |sms| sms.created_at_timezone }
    column :status
  end

  form do |f|
    f.inputs do
      f.input :from
      f.input :to
      f.input :body
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :restaurant
      row :restaurant_address do |sms|
        link_to sms.restaurant_address.name, admin_restaurant_address_path(restaurant_id: sms.restaurant_id, id: sms.restaurant_address_id) if sms.restaurant.present? && sms.restaurant_address.present?
      end
      row :from
      row :to
      row :body
      row :failed_reason
      row :created_at { |sms| sms.created_at_timezone }
      row :status do |sms|
        if sms.pending?
          status_tag( :pending )
        elsif sms.sent?
          status_tag( :sent )
        elsif sms.cancelled?
          status_tag( :cancelled )
        else
          status_tag( :failed )
        end
      end
    end
  end

  member_action :cancel, method: :get do
    sms_log = SmsLog.find(params[:id])
    sms_log.cancelled!
    redirect_to admin_sms_logs_path, notice: "Sms has been successfully cancelled"
  end
  controller do
    def scoped_collection
      SmsLog.left_joins(:restaurant)
    end
  end

  filter :name
  filter :restaurant_id, as: :search_select_filter, url: proc { restaurants_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :restaurant, as: :select, collection: proc{ Restaurant.active }
  filter :restaurant_address_id, as: :search_select_filter, url: proc { restaurant_addresses_admin_addresses_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :restaurant_address, as: :select, collection: proc{ RestaurantAddress.active }
  filter :from
  filter :to
  filter :body
  filter :status, as: :select, collection: SmsLog.statuses


end
