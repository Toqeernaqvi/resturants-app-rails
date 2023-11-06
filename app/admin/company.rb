ActiveAdmin.register Company, as: 'Company' do
  menu priority: 2
  config.batch_actions = false
  actions :all, :except => :destroy
  permit_params do
    permitted = [
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
      :allow_users_to_onboard_without_admin_approval,
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
        :separate_out_sales_tax_on_invoices,
        :service_fee,
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
        :time_zone
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
        :parent_status,
        :user_id,
        :lunch_sequence_id,
        :dinner_sequence_id,
        :breakfast_sequence_id,
        :buffet_sequence_id,
        :grouping_rows,
        :grouping_columns,
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
      ],
    ]
  end

  index do
    column :id
    column :name
    column :status do |company|
      if company.active?
        status_tag( :active )
      else
        status_tag( :deleted )
      end
    end
    actions do |company|
      if company.active?
        item('Delete', delete_admin_company_path(company.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_company_path(company.id) , class: [:member_link, :active_btn])
      end
      # if company.site_survey.present?
      #   item('Site Survey Pdf', download_pdf_admin_company_path(company.id), class: [:member_link])
      # end
    end
  end

  csv do
    column :id
    column :name
  end

  form do |f|
    tabs do
      tab 'Company' do
        f.inputs do
          f.input :name
          f.input :user_meal_budget, label: "Per User Per Meal Budget"
          f.input :markup, label: "Markup($)"
          f.input :buffet_addons_markup, label: "Buffet Addons Markup(%)", input_html: {value: f.object.new_record? ? "30.0" : f.object.buffet_addons_markup, min: '0', step: '0.1', onclick: "this.select();"}
          f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
          f.input :parent_company_id, as: :select, collection: Company.active.where("parent_company_id IS NULL AND id != ?", f.object.id).pluck(:name, :id) unless f.object.childs.present?
          ol :class => "wrapper_markup_ol" do
            f.input :reduced_markup_check, as: :boolean, label: "Over Budget Compensation"
            f.input :reduced_markup, label: "Reduced Markup(%)"
            f.input :user_copay, as: :boolean, label: "Allow User Copay"
            f.input :copay_amount, label: "Copay Amount($)"
            f.input :show_remaining_budget, as: :boolean, label: "Show Remaining Budget"
            f.input :enable_grouping_orders
            f.input :allow_users_to_onboard_without_admin_approval
          end
          f.input :image, label: false , as: :file, hint: image_tag(f.object.image.thumb)
          f.input :location_ids, as: :selected_list, url: ban_addresses_admin_companies_path, minimum_input_length: 3, input_html: { class: 'restaurants_tags', multiple: true }, label: "Ban Restaurants", hint: "Select restaurants you don't want to order in."
          f.has_many :company_admins_active, heading: nil, new_record: true do |a|
            a.input :email
            a.input :first_name
            a.input :last_name
            a.input :phone_number
            a.input :desk_phone, label: "Desk Phone"
            a.input :time_zone, input_html: { value: f.object.time_zone, class: "timezone" }, as: :hidden
          end
          f.has_many :addresses_active, heading: nil, new_record: true do |a|
            a.input :address_line, label: "Address", input_html: {id: "autocomplete", class: "autocomplete", onFocus: 'geolocate(this);', autocomplete: :off}, :placeholder => 'Enter Your Address'
            a.input :address_name, label: "Name"
            a.input :short_code
            a.input :suite_no, label: "Suite Number"
            a.input :grouping_rows, label: 'Number of Shelves'
            a.input :grouping_columns, label: 'Number of Items per Shelf'
            a.input :delivery_instructions, input_html: { class: 'special_request_text_area' }
            # a.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
            a.input :street_number, :input_html =>{:id => "street_number"}, :as => :hidden
            a.input :street, :input_html =>{:id => "route"}, :as => :hidden
            a.input :city, :input_html =>{:id => "locality"}, :as => :hidden
            a.input :state, :input_html =>{:id => "administrative_area_level_1"}, :as => :hidden
            a.input :zip, :input_html =>{:id => "postal_code"}, :as => :hidden
            a.input :longitude, :input_html =>{:id => "longitude"}, :as => :hidden
            a.input :latitude, :input_html =>{:id => "latitude"}, :as => :hidden
            a.input :default_admin, as: :select, collection: f.object.company_admins_active.all
            a.input :lunch_sequence_id, as: :select, collection: LunchSequence.active
            a.input :dinner_sequence_id, as: :select, collection: DinnerSequence.active
            a.input :breakfast_sequence_id, as: :select, collection: BreakfastSequence.active
            a.input :buffet_sequence_id, as: :select, collection: BuffetSequence.active
            unless a.object.new_record?
              a.input :parent_status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
            end
          end

          f.has_many :fields_active, sortable: :position, sortable_start: 1, new_record: 'Add New Custom Field', heading: nil do |f|
            f.input :field_type, input_html: { class: 'company_field_type' }
            f.input :name, label: "Name"
            f.input :required, as: :boolean, label: "Required"
            f.has_many :fieldoptions, sortable: :position, sortable_start: 1, heading: nil, new_record: true do |f|
              f.input :name, label: "Name"
              unless f.object.new_record?
                f.input :status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
              end
            end
            unless f.object.new_record?
              f.input :status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active"
            end
          end
        end
      end
      tab 'Billing Detail', html_options: { class: (f.object.billing.present? && f.object.billing.errors.present?) ? 'ui-tabs-active ui-state-active' : '' } do
        f.inputs "", for: [:billing, f.object.billing || Billing.new] do |a|
          a.input :invoice_credit_card, :as => :radio, label: false, :collection =>  Billing.invoice_credit_cards.keys.map{|a| [a.split("_").map(&:capitalize).join(" "), a]}
          a.input :card_number
          a.input :expiry_month
          a.input :expiry_year
          a.input :cvc
          a.input :change_card, :as => :boolean if f.object.billing.present? && f.object.billing.customer_id.present?
          a.input :delivery_fee, label: "Delivery & Service Fee"
          a.input :disable_auto_invoice, :as => :boolean, label: "Disable Auto Invoice"
          a.input :name
          a.input :separate_out_sales_tax_on_invoices, as: :boolean
          a.input :service_fee, label: "Service Fee ( % )"
          # a.input :weekly_invoice, :as => :boolean, label: "Weekly Invoice"
          a.input :updated_from_backend, :as => :hidden, input_html: { value: 'true' } if f.object.billing.present? && !f.object.billing.customer_id.present? && f.object.billing.credit_card?
          a.has_many :addresses , heading: nil, new_record: true do |c|
            c.input :address_line
            c.input :city
            c.input :state
            c.input :zip
          end
          a.has_many :approvers, class: "approver_", heading: nil, allow_destroy: true, new_record: true do |b|
            b.input :name
            b.input :email
            b.has_many :addresses , heading: nil, new_record: true do |c|
              c.input :address_line
              c.input :city
              c.input :state
              c.input :zip
            end
          end
        end
      end
      tab 'Site Survey & Notes' do
        f.inputs do
          f.input :site_survey, label: "Site Survey", as: :ckeditor#, input_html: {toolbar: 'mini'}
          f.input :delivery_notes, label: "Delivery Notes", as: :ckeditor
        end
      end
      tab 'Marketplace' do
        f.inputs do
          f.input :enable_marketplace
          f.input :enable_saas, label: "Enable SaaS"
        end
      end
      # tab 'Sequence' do
      #   f.inputs do
      #     f.input :sequence_id, as: :select, collection: Sequence.active
      #   end
      # end
      f.actions do
        f.action(:submit)
        f.cancel_link
      end
    end
  end

  show do
    div class: "companyShowData" do
      if company.present?
        panel "Company Detail" do
          table_for company do
            column :name
            column :user_meal_budget
            column :markup
            column :buffet_addons_markup
            column :reduced_markup
            column :copay_amount
            column :enable_grouping_orders
            column :enable_marketplace
            column :enable_saas
            column :allow_users_to_onboard_without_admin_approval
            if company.parent_company.present?
              column "Parent Company" do
                company.parent_company.name
              end
            end
          end
        end
      end
      if company.users.active.where(user_type: User.user_types[:company_admin]).present?
        panel "Company Admins" do
          table_for company.users.active.where(user_type: User.user_types[:company_admin]).order(status: :asc) do
            column :first_name
            column :last_name
            column :email
            tag_column :parent_status, interactive: true
            column 'Resend Invite' do |company_admin|
              link_to link_to('Resend Invite', resend_invite_admin_company_path(company_admin: company_admin), method: :put) unless company_admin.confirmed? && company_admin.encrypted_password.present?
            end
          end
        end
      end
      if company.users.active.where(user_type: User.user_types[:company_user]).present?
        panel "Company Users" do
          table_for company.users.active.where(user_type: User.user_types[:company_user]).order(status: :asc) do
            column :office_admin_id do |o|
              o.office_admin.name if o.office_admin.present?
            end
            column :first_name
            column :last_name
            column :email
            tag_column :parent_status, interactive: true
            column 'Resend Invite' do |companyuser|
              link_to link_to('Resend Invite', resend_invite_user_admin_company_path(companyuser: companyuser), method: :put) unless companyuser.confirmed? && companyuser.encrypted_password.present?
            end
          end
        end
      end
      if company.addresses.present?
        panel "Addresses" do
          table_for company.addresses.order(status: :asc) do
            column :id
            column ("Address") {|a| a.address_line}
            column ("Name") {|a| a.address_name}
            column :street_number
            column :street
            column :city
            column :state
            column :zip
            column :short_code
            column :suite_no
            column :delivery_instructions
            column ("Number of Shelves") {|a| a.grouping_rows}
            column ("Number of Items per Shelf") {|a| a.grouping_columns}
            column :default_admin
            column :lunch_sequence
            column :dinner_sequence
            column :breakfast_sequence
            column :buffet_sequence
            column "Status" do |a|
              render partial: 'admin/companies/status_changer', locals: {addr: a}
            end
          end
        end
      end
      if company.ban_addresses.present?
        panel "Ban Restaurants" do
          table_for company.ban_addresses do
            column :address
          end
        end
      end
      if company.fields.present?
        panel "Fields" do
          table_for company.fields.order(position: :asc) do
            column :id
            column :field_type
            column :name
            tag_column :status, interactive: true
          end
        end
      end
      if company.childs.present?
        panel "Childs" do
          table_for company.childs do
            column :id
            column :name
            # tag_column :status, interactive: true
          end
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/company_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Company").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end
  collection_action :companies, method: :get do
    companies = Company.active.where("name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: companies.collect {|company| {:id => company.id, :name => company.name} }
  end
  collection_action :company_addresses, method: :get do
    company_addresses = Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id").where("addresses.address_line ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: company_addresses.collect {|company_address| {:id => company_address.id, :name => company_address.name} }
  end
  collection_action :ban_addresses, method: :get do
    addresses = RestaurantAddress.active.distinct.joins(:menus, ' INNER JOIN restaurants ON addresses.addressable_id = restaurants.id').where("restaurants.name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: addresses.collect {|address| {:id => address.id, :name => address.name} }
  end

  member_action :delete, method: :get do
    company = Company.find(params[:id])
    if company.active?
      company.parent_status_deleted!
      company.deleted!
      redirect_to admin_companies_path, notice: "Company has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    company = Company.find(params[:id])
    if company.deleted?
      company.active!
      company.parent_status_active!
      redirect_to admin_companies_path, notice: "Company haas been successfully active"
    end
  end

  member_action :resend_invite, method: :put do
    user = User.find(params[:company_admin]).send_confirmation_instructions
    redirect_to admin_companies_path, notice: 'Invite has been sent successfully!'
  end

  member_action :resend_invite_user, method: :put do
    User.find(params[:companyuser]).send_confirmation_instructions
    redirect_to admin_companies_path, notice: 'Invite has been sent successfully!'
  end

  collection_action :download_pdf, method: :get do
    if params[:id].present?
      id = Base64.decode64(params[:id])
      company = Company.find(id)
      pdf = WickedPdf.new.pdf_from_string(company.site_survey.gsub('https', 'http'))
      send_data pdf, filename: "#{company.name} site_survey", :disposition => 'inline', :type => "application/pdf", :target => '_blank'
      #send_file(pdf_filename, :filename => "your_document.pdf", :disposition => 'inline', :type => "application/pdf")
    end
  end

  filter :name
  filter :status, as: :select, collection: -> { Company.statuses }
  filter :enable_marketplace, label: "Marketplace", as: :select, collection: [['Yes', true],['No', false]]

  controller do
    before_action :set_paper_trail_whodunnit
    skip_before_action :authenticate_active_admin_user, only: [:download_pdf]
    skip_before_action :verify_authenticity_token, :only => [:update]

    def create
      create! {|failure|
        if failure.present? && resource.addresses.blank? && !resource.name.blank? && !resource.image.blank?
          failure.html do
              flash[:notice] = "Company Must have one address"
              render :edit
          end
        end
      }
    end

    def update
      if params[:user].present?
        User.find(params[:id]).update(parent_status: params[:user][:parent_status])
      elsif params[:address].present?
        addr = CompanyAddress.find(params[:id])
        if addr.addressable.addresses.parent_status_active.count == 1 && params[:address][:parent_status] == 'deleted'
          render json: {success: false}, status: 406
        else
          # addr.update(parent_status: params[:address][:parent_status])
          # render json: {success: true}
          if addr.update(parent_status: params[:address][:parent_status])
            render json: {success: true}
          else
            render json: { message: addr.errors.full_messages[0]}, status: 406
          end
        end
      elsif params[:field].present?
        Field.find(params[:id]).update(status: params[:field][:status])
      else
        count = 0
        if params[:company][:addresses_active_attributes].present?
          params[:company][:addresses_active_attributes].each do |number , a|
            if a[:parent_status] == "active" || a[:parent_status].blank?
              count += 1
              break
            end
          end
          if count == 1
            update!
          else
            flash[:notice] = "Company Must have one address"
            render :edit
          end
        else
          flash[:notice] = "Company Must have one address"
          render :edit
        end
      end
    end
  end
end
