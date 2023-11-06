ActiveAdmin.register Order do
  menu parent: 'Orders', priority: 1
  config.batch_actions = false
  config.clear_action_items!
  actions :all, :except => [:destroy, :create ]
  permit_params do
    permitted = [:discount, :quantity, :red_type]
  end
  # sidebar :versionate, :partial => "layouts/version", :only => :show

  form do |f|
    tabs do
      f.inputs do
        f.input :red_type, input_html: { value: params[:a] }, as: :hidden
        f.input :quantity
        f.input :fooditem, label: "Item name", required: false, input_html: { disabled: true }
        f.input :price, input_html: { disabled: true }
        f.input :total_price, input_html: { disabled: true }
        f.input :discount
      end
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  index do
    column :id
    column 'User', :first_name, :sortable => 'users.first_name' do |o|
      if o.share_meeting.present? && o.share_meeting.name.present?
        span do
        mail_to o.share_meeting.email, o.share_meeting.name
        end
      elsif o.guest.present?
        span do
          o.guest.name
        end
      elsif o.user.deleted?
        span do
          o.user.name
        end
        span do
          status_tag( :deleted )
        end
      else
        o.user
      end
    end
    column "Company", :name, :sortable => 'companies.name' do |o|
      if o.runningmenu.company.deleted?
        span do
          o.runningmenu.company.name
        end
        span do
          status_tag( :deleted )
        end
      else
        o.runningmenu.company
      end
    end
    column "Restaurant", :name , sortable: 'restaurants.name' do |o|
      if o.restaurant&.deleted?
        span do
          o.restaurant.name
        end
        span do
          status_tag( :deleted )
        end
      else
        o.restaurant
      end
    end
    column ("Address") {|o| o.runningmenu.address.address_line}
    column "fooditem", :name, sortable: 'fooditems.name' do |o|
      o.fooditem&.name
    end
    column ("Schedule") {|o| o.runningmenu}
    column :price, class: "textAlignRight" do |o|
      number_with_precision(o.price, precision: 2)
    end
    column "Company Paid", class: "textAlignRight" do |o|
      number_with_precision(o.company_price, precision: 2)
    end
    column "User Paid", class: "textAlignRight" do
      |o| o.user_price
    end
    column "Markup", class: "textAlignRight" do |o|
      o.site_price
    end
    column :quantity
    column :total_price, class: "textAlignRight" do |o|
      number_with_precision(o.total_price, precision: 2)
    end
    column :discount, class: "textAlignRight" do |o|
      number_with_precision(o.discount, precision: 2)
    end
    column "Disounted Total Price", class: "textAlignRight" do |o|
      number_with_precision(o.total_price-o.discount, precision: 2)
    end
    column ('Deliver Date') {|o| o.runningmenu.delivery_at_timezone}
    column "Invoice ID" do |o|
       o.invoice
    end
    column ("Sales Tax") {|o| o.sales_tax&.truncate(2)}
    column ("Restaurant Commission") {|o| o.restaurant_commission&.truncate(2)}
    column ("Restaurant Payout") {|o| o.restaurant_payout&.truncate(2)}
    column :number_of_meals
    column :status do |order|
      if order.active?
        status_tag( :active )
      else
        status_tag( :deleted )
      end
    end

    actions defaults: false do |order|
      item('View', admin_order_path(order.id), class: :member_link)
      if order.runningmenu.delivery_at > Time.current && order.runningmenu.parent_status_active?
        item('Edit', edit_admin_order_path(order.id), class: :member_link)
        if order.active?
          item('Cancel', cancel_admin_order_path(order.id), class: [:member_link, :delete_btn])
        elsif order.runningmenu.addresses_runningmenus.where(address_id: order.restaurant_address_id).present?
          item('Activate', active_admin_order_path(order.id), class: [:member_link, :active_btn])
        end
      end
    end
  end

  csv do
    column :id
    column ("User") {|o| o.model_user_name}
    column ("Email") {|o| o.user.email if o.user.present?}
    column ("Company") {|o| o.runningmenu.company.name}
    column ("Restaurant") {|o| o.restaurant.name if o.restaurant.present?}
    column ("Company Address") {|o| o.runningmenu.address.address_line}
    column ("Fooditem") {|o| o.fooditem.name if o.fooditem.present?}
    column ("Schedule Id") {|o| o.runningmenu_id}
    column ("Company Paid") {|o| o.company_price}
    column ("User Paid") {|o| o.user_price}
    column ("Markup") {|o| o.site_price}
    column ("Sales Tax") {|o| o.sales_tax&.truncate(2)}
    column ("Restaurant Commission") {|o| o.restaurant_commission&.truncate(2)}
    column ("Restaurant Payout") {|o| o.restaurant_payout&.truncate(2)}
    column :number_of_meals
    column :quantity
    column :total_price
    column :discount
    column "Disounted Total Price" do |o|
      o.total_price-o.discount
    end
    column ("Order Fields"){|o|
    if o.runningmenu.runningmenufields.present?
      o.runningmenu.runningmenufields.map do |runningmenu_field|
        if runningmenu_field.field.present? && runningmenu_field.fieldoption.present?
          runningmenu_field.field.name + " : " + runningmenu_field.fieldoption.name
        elsif runningmenu_field.field.present? && runningmenu_field.value.present?
          runningmenu_field.field.name + " : " + runningmenu_field.value
        end
      end.join(', ')
    end
    }
    column ("Selected Options") { |o|
      o.optionsets_orders&.map{|os| "#{os.optionset.name}: #{os.options.pluck(:description)&.compact&.join(', ')}" }&.compact&.join(", ")
    }
    column ('Deliver Date') {|o| o.runningmenu.delivery_at_timezone.strftime("%B %d, %Y")}
    column ('Deliver Time') {|o| o.runningmenu.delivery_at_timezone.strftime("%H:%M")}
    column ('Deliver Instructions') {|o| o.runningmenu.delivery_instructions}
    column ('Extra Instructions') {|o| o.remarks }
    column :status
    column :group
  end

  show do
    attributes_table do
      row :id
      row :user do |o|
        if o.user.deleted?
          span do
            o.user.name
          end
          span do
            status_tag( :deleted )
          end
        else
          o.model_user_name
        end
      end
      row :admin do |o|
        if(o.guest.present?)
          o.user&.name
        end
      end
      row :company do |r|
        if r.runningmenu.company.deleted?
          span do
            r.runningmenu.company.name
          end
          span do
            status_tag( :deleted )
          end
        else
          r.runningmenu.company.name
        end
      end
      row :restaurant
      row ("Address"){|o| o.runningmenu.address.address_line}
      row :runningmenu
      row :fooditem do |o|
        fieldset do
          legend :class => "order_fooditems" do
            o.fooditem&.name
          end
          o.optionsets_orders.each do |optionsets_order|
            if optionsets_order.optionset.present?
              fieldset do
                legend do
                  optionsets_order.optionset.name if optionsets_order.optionset.present?
                end
                optionsets_order.options_orders.each do |options_order|
                  span do
                    options_order.option.description if options_order.option.present?
                  end
                end
              end
            end
          end
        end
      end
      row "Delivery Date" do |o|
        o.runningmenu.delivery_at_timezone
      end
      row :created_at
      row :updated_at
      row ("Deleted At"){|o| o.cancelled_time}
      row :price {|o| number_with_precision(o.price, precision: 2)}
      row :company_price {|o| number_with_precision(o.company_price, precision: 2)}
      row :user_price {|o| number_with_precision(o.user_price, precision: 2)}
      row :site_price {|o| number_with_precision(o.site_price, precision: 2)}
      row :quantity
      row :total_price {|o| number_with_precision(o.total_price, precision: 2)}
      row :discount {|o| number_with_precision(o.discount, precision: 2)}
      row "Disounted Total price" do |o|
        number_with_precision(o.total_price-o.discount, precision: 2)
      end
      row "Order Fields" do |o|
        if o.runningmenu.runningmenufields.present?
          o.runningmenu.runningmenufields.map do |runningmenu_field|
            if runningmenu_field.field.present? && runningmenu_field.fieldoption.present?
              runningmenu_field.field.name + " : " + runningmenu_field.fieldoption.name
            elsif runningmenu_field.field.present? && runningmenu_field.value.present?
              runningmenu_field.field.name + " : " + runningmenu_field.value
            end
          end.join(', ')
        end
      end
      row ("Delivery Instructions"){|o| o.runningmenu.delivery_instructions}
      row "Invoice ID" do |o|
         o.invoice
      end
      row :status do |order|
       if order.active?
         status_tag( :active )
       else
         status_tag( :deleted )
       end
      end
      row :group
      panel "Audit log" do
        render partial: '/active_admin/versions/order_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Order").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  member_action :cancel, method: :get do
    order = Order.find(params[:id])
    if order.active?
      order.update(parent_status: :deleted, status: :cancelled)
      order.update_column(:cancelled_time, Time.current)
      redirect_to admin_orders_path, notice: "Order has been successfully cancelled"
    end
  end

  member_action :active, method: :get do
    order = Order.find(params[:id])
    if !order.runningmenu.addresses.include?(order.restaurant_address)
      redirect_to admin_orders_path, alert: "Order's restaurant is not Scheduled"
    elsif order.cancelled?
      if order.update(parent_status: :active, status: :active)
        redirect_to admin_orders_path, notice: "Order has been successfully active"
      else
        redirect_to admin_orders_path, alert: "#{order.errors.full_messages.last}"
      end
    end
  end

  collection_action :fooditems, method: :get do
    fooditems = Fooditem.active.distinct.joins(:orders).where("(name ILIKE :prefix)", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: fooditems.collect {|cl| {:id => cl.id, :name => cl.name} }
  end

  controller do
    before_action :set_paper_trail_whodunnit
    def scoped_collection
      end_of_association_chain.includes([:user, :company, :restaurant, :fooditem])
    end

    def update
      resource.quantity, resource.discount = update_params[:quantity], update_params[:discount]
      if resource.save
        if update_params[:red_type] == "invoice"
          path = admin_invoice_path(resource.invoice_id)
        else
          path = admin_order_path(resource.id)
        end
        redirect_to path, flash: {notice: "Successfully updated the order"}
      else
        redirect_to edit_admin_order_path(resource.id), flash: {alert: resource.errors.full_messages.first}
      end

    end

    def update_params
      params.require(:order).permit(:quantity, :discount, :red_type)
    end
  end

  filter :status, as: :select, collection: -> { Order.statuses }
  filter :guest_id_or_share_meeting_id_not_null, label: 'Guest?', as: :boolean
  filter :user_id, label: 'User Name', as: :search_select_filter, url: proc { admin_users_path }, fields: [:first_name, :last_name], display_name: 'name', minimum_input_length: 3, width: '233px'
  # filter :runningmenu_company_id, label: 'Company', as: :select, collection: proc{ Company.active.all.pluck(:name, :id) }
   filter :company_id, input_html: {name: 'q[runningmenu_company_id_eq]'}, as: :search_select_filter, url: proc {  companies_admin_companies_path

 }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px', method_model: Order
  # filter :company_id, as: :search_select_filter, url: proc {runningmenu_company_admin_orders_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px'
  # filter :company_id, as: :search_select_filter, url: proc { admin_companies_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px'
  filter :restaurant_id, as: :search_select_filter, url: proc { admin_restaurants_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px'
  filter :address_id, input_html: {name: 'q[runningmenu_address_id_eq]'}, as: :search_select_filter, url: proc { company_addresses_admin_companies_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px', method_model: Order
  # filter :runningmenu_address_id, label: 'Address', as: :select, collection: proc{ Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id") }
  # filter :address_id, as: :search_select_filter, input_html: {name: 'q[address_id_in]'}, url: proc { company_addresses_admin_orders_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px'
  filter :fooditem_id, as: :search_select_filter, url: proc { fooditems_admin_orders_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, width: '233px'
  filter :runningmenu_delivery_at, label: 'Delivery Date', as: :date_range
  filter :total_price, label: 'Total Price', as: :numeric
  filter :runningmenu_id, label: 'Schedule', as: :search_select_filter, url: proc { admin_schedulers_path }, fields: [:id], display_name: 'id', minimum_input_length: 1, width: '233px'
  # filter :user_id, label: 'User Name', as: :select, collection: proc{ User.active.map{ |u| [u.name, u.id] } }
  # filter :restaurant_id, label: 'Restaurant', as: :select, collection: proc{ Restaurant.active.all.pluck(:name, :id) }
  # filter :runningmenu_address_id, label: 'Address', as: :select, collection: proc{ Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id") }
  # filter :fooditem_id, label: 'Fooditem Name', as: :select, collection: -> { Fooditem.all.pluck(:name, :id) }
  # filter :share_meeting_id, label: 'Email', as: :select, collection: proc{ ShareMeeting.all.pluck(:email, :id) }
  # filter :runningmenu_id, as: :select, label: "Schedule", collection: proc { Runningmenu.pluck(:id)}
end
