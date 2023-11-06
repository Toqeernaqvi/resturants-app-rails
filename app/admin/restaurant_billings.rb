ActiveAdmin.register RestaurantBilling do
  menu parent: 'Finance'
  config.clear_action_items!
  permit_params do
    permitted = [
      :status,
      :payment_status,
      :payment_method,
      :credit_card_fees,
      :due_date,
      :paid_on,
      :tips,
      adjustments_attributes: [
        :id,
        :_destroy,
        :adjustment_date,
        :description,
        :price,
      ]
    ]
  end
  actions :all, except: [:new, :create, :destroy]

  # config.batch_actions = false

  batch_action :download, format: :pdf do |ids|
    FileUtils.mkdir_p 'public/billing'
    FileUtils.mkdir_p 'public/billingzip'
    path = []
    batch_action_collection.find(ids).each do |bill|
      ac = ActionController::Base.new()
      file_path = "Restaurant Billing #{bill.billing_number}.pdf"
      path.push(file_path)
      template_path = bill.buffet? ? "admin/restaurant_billings/detail_pdf_buffet.html.erb" : "admin/restaurant_billings/detail_pdf.html.erb"

      pdf = ac.render_to_string pdf: file_path, template: template_path, locals: { billing: bill }, encoding: "UTF-8"
      save_path = Rails.root.join('public','billing', file_path)
      File.open(save_path, 'wb') do |file|
        file << pdf
      end
    end
    folder = Rails.root.join('public','billing')
    zipfile_name = Rails.root.join('public','billingzip',"billing #{Date.today}.zip")

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      path.each do |filename|
        zipfile.add(filename, File.join(folder, filename))
      end
    end
    file = File.open(Rails.root.join('public','billingzip',"billing #{Date.today}.zip"), "rb")
    contents = file.read
    file.close
    File.delete(Rails.root.join('public','billingzip',"billing #{Date.today}.zip")) if File.exist?(Rails.root.join('public','billingzip',"billing #{Date.today}.zip"))
    path.each do |f_name|
      File.delete(Rails.root.join('public','billing',f_name)) if File.exist?(Rails.root.join('public','billing', f_name))
    end
    send_data(contents, :type => 'application/zip', :filename => "billing.zip")
  end

  form  do |f|
    f.input :payment_status, as: :select, collection: RestaurantBilling.payment_statuses.keys
    f.input :payment_method, as: :select, collection: RestaurantBilling.payment_methods.keys.map{|a| [a.split("_").map(&:capitalize).join(" "), a]}
    f.input :credit_card_fees
    f.input :tips
    f.input :due_date, as: :date_time_picker, input_html: { autocomplete: :off }, picker_options: { timepicker: false, format: "Y-m-d", value: f.object.due_date.try(:strftime, '%Y-%m-%d') }
    f.input :paid_on, as: :date_time_picker, input_html: { autocomplete: :off }, picker_options: { timepicker: false, format: "Y-m-d", value: f.object.due_date.try(:strftime, '%Y-%m-%d') }

    f.has_many :adjustments, heading: false, allow_destroy: true do |a|
      a.input :adjustment_date, label: "Date"
      a.input :description, input_html: {class: 'description'}
      a.input :price, label: "Amount( $ )"
    end

    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  index do
    selectable_column
    column :id
    column :billing_number
    column :billing_type do |b|
      status_tag(b.billing_type.to_sym)
    end
    column :restaurant
    column :address { |b| link_to b.address.name, admin_restaurant_address_path(b.restaurant.id,b.address.id)}
    column ("Delayed Payout by Days") {|b| b.address.delayed_payout_days }
    column "Discount Percentage", class: "textAlignRight" do |b|
      # (b.orders.sum(&:quantity) >= b.address.items_count || b.food_total >= b.address.minimum_discount_price) && b.address.add_contract_commission ? (b.address.discount_percentage + b.address.buffet_commission) : b.address.discount_percentage
      b.discount_percentage
    end
    column "Total Orders", class: "textAlignRight" do |b|
      b.orders.active.sum(:quantity).to_i
    end
    column "Sales Tax", class: "textAlignRight" do |b|
      b.sales_tax.to_s + " (#{(sprintf "%.2f", b.sale_tax_percentage*100)}%)"
    end
    column ("Orders From") {|b| b.orders_from_timezone }
    column ("Orders To") {|b| b.orders_to_timezone }
    column "Food Total", class: "textAlignRight" do |b|
       b.food_total
    end
    column 'Commission', :commission, class: "textAlignRight", sortable: :commission {|b| b.commission }
    column :tips, class: "textAlignRight"
    column :credit_card_fees, class: "textAlignRight"
    column "Total Payout", class: "textAlignRight" do |b|
       b.payout_total
    end
    column :created_at
    column :due_date
    column :paid_on
    tag_column :payment_status, interactive: true
    actions defaults: false do |billing|
      item 'View', admin_restaurant_billing_path(billing), class: :member_link
      item 'Edit', edit_admin_restaurant_billing_path(billing), class: :member_link if !billing.paid?
      if billing.active?
        item('Delete', delete_admin_restaurant_billing_path(billing.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_restaurant_billing_path(billing.id), class: [:member_link, :active_btn])
      end
      # if billing.paid?
      #   item('Generated', generated_admin_restaurant_billing_path(billing.id), class: [:member_link, :generated_btn])
      # else
      #   item('Paid', paid_admin_restaurant_billing_path(billing.id), class: [:member_link, :paid_btn])
      # end
      item('PDF', generate_PDF_admin_restaurant_billing_path(id: billing.id, format: :pdf), class: :member_link)
      item('Payout', stripe_payout_admin_restaurant_billing_path(id: billing.id), class: :member_link) if billing.address.stripe_details_submitted && billing.due? && billing.stripe_payout_id.nil?
    end
  end

  show do
    attributes_table do
      row :id
      row :billing_number
      row :restaurant
      row :address { |b| link_to b.address.name, admin_restaurant_address_path(b.restaurant.id,b.address.id)}
      row "Delayed Payout by Days" do |b|
        b.address.delayed_payout_days
      end
      row ("Discount Percentage") {|b| b.address.discount_percentage }
      row :payment_method do |b|
        if b.credit_card?
          "Credit Card"
        else
          "Check"
        end
      end
      row ("Total Orders") {|b| b.orders.active.sum(:quantity).to_i }
      row ("Sales Tax") {|b| b.sales_tax }
      row ("Orders From") {|b| b.orders_from_timezone }
      row ("Orders To") {|b| b.orders_to_timezone }
      row ("Food Total") {|b| b.food_total}
      row ("Commission") {|b| b.commission }
      row :tips
      row :credit_card_fees
      row ("Total Payout") {|b| b.payout_total }
      row :created_at
      row :due_date
      row :paid_on
      row :payment_status
      ol 'Billing Items', :class => "wrapper_optionset" do
        render partial: 'billing-items', locals: { object: resource }
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/restaurant_billing_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"RestaurantBilling").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  member_action :generate_PDF, method: :get do
    respond_to do |format|
      format.html
      format.pdf do
        if resource.buffet?
          render pdf: "Restaurant Billing #{Date.today}", template: 'admin/restaurant_billings/detail_pdf_buffet.html.erb', locals: { billing: resource}
        else
          render pdf: "Restaurant Billing #{Date.today}", template: 'admin/restaurant_billings/detail_pdf.html.erb', locals: { billing: resource}
        end
      end
    end
  end

  member_action :stripe_payout, method: :get do
    amount = resource.payout_total*100
    begin
      payout = Stripe::Payout.create({
        amount: amount.to_i,
        currency: 'usd',
      }, {
        stripe_account: resource.address.stripe_acc_id,
      })
      if payout.failure_code.nil?
        resource.update_columns(stripe_payout_id: payout.id)
        resource.paid!
        redirect_to admin_restaurant_billings_path, notice: "Billing id: #{resource.id} status change to paid successfully."
      else
        redirect_to admin_restaurant_billings_path, notice: "Billing id: #{resource.id} status not changed due to #{payout.failure_message}"
      end
    rescue => e
      redirect_to admin_restaurant_billings_path, notice: "Billing id: #{resource.id} status not changed due to #{e.message}"
    end
  end

  member_action :delete, method: :get do
    if resource.active?
      resource.deleted!
      redirect_to admin_restaurant_billings_path, notice: "Billing has been deleted successfully."
    end
  end

  member_action :active, method: :get do
    if resource.deleted?
      resource.active!
      redirect_to admin_restaurant_billings_path, notice: "Billing is active now."
    end
  end

  member_action :generated, method: :get do
    if resource.paid?
      resource.generated!
      redirect_to admin_restaurant_billings_path, notice: "Billing status change to generated successfully."
    end
  end

  member_action :paid, method: :get do
    if resource.generated?
      resource.paid!
      redirect_to admin_restaurant_billings_path, notice: "Billing status change to paid successfully."
    end
  end

  collection_action :preferred_partners, method: :get do
    preferred_partners =Restaurant.active.joins(:addresses).where("addresses.discount_percentage > ?", 0.0).where("(name ILIKE :prefix)", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%").uniq
    render json: preferred_partners.collect {|cl| {:id => cl.name, :name => cl.name} }
  end

  controller do
    before_action :set_paper_trail_whodunnit
    skip_before_action :verify_authenticity_token, :only => [:update]
    include ActionView::Helpers::NumberHelper
  end

  filter :billing_number, label: "Bill Number"
  filter :billing_type, as: :select, collection: -> { RestaurantBilling.billing_types }
  # filter :restaurant_name, label: 'Preferred Partners', :as => :select, collection: proc { Restaurant.active.joins(:addresses).where("addresses.discount_percentage > ?", 0.0).pluck(:name).uniq }
  filter :orders_id, input_html: {name: 'q[restaurant_name_eq]'}, label: 'Preferred Partners', as: :search_select_filter, url: proc { preferred_partners_admin_restaurant_billings_path	 }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  filter :restaurant_id, as: :search_select_filter, url: proc { restaurants_admin_users_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
   filter :address_id, as: :search_select_filter, url: proc { restaurant_addresses_admin_addresses_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :user_id, as: :search_select_filter, url: proc { restaurants_list_admin_restaurant_billings_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
  # filter :restaurant_id, as: :select, collection: proc { Restaurant.active.pluck(:name, :id) }
  # filter :address_id, as: :select, collection: proc { RestaurantAddress.active.pluck(:address_line, :id) }
  filter :payment_status, as: :select, collection: -> { RestaurantBilling.payment_statuses }
  filter :due_date, as: :date_range
  filter :paid_on, as: :date_range
  filter :orders_from, as: :date_range
  filter :orders_to, as: :date_range
  filter :all_preferred_partner_in, label: "All Preferred Partners",  as: :select, collection: [['Yes', 'Yes']]
end
