ActiveAdmin.register RecurringScheduler do
  menu parent: 'Schedulers', priority: 2
  config.batch_actions = false
  config.clear_action_items!
  actions :all, except: :destroy

  action_item only: [:index] do
    link_to 'Create Manual Schedulers', admin_manual_schedulers_path, class: 'linksForScope'
  end

  action_item :edit, only: [:show] do
    link_to 'Edit Schedular', edit_admin_recurring_scheduler_path(recurring_scheduler)
  end

  action_item :new, only: [:index] do
    link_to 'New Recurring Scheduler', new_admin_recurring_scheduler_path
  end

  permit_params do
    permitted = [
      :runningmenu_type,
      :runningmenu_name,
      :address_id,
      :special_request,
      :per_meal_budget,
      :per_user_copay,
      :per_user_copay_amount,
      :menu_type,
      :orders_count,
      :user_id,
      :hide_meeting,
      :restaurant_deleted,
      :deleted_restaurant_name,
      :driver_id,
      :approve_ban_restaurant,
      :submitted_from_backend,
      :monday,
      :tuesday,
      :wednesday,
      :thursday,
      :friday,
      :saturday,
      :sunday,
      :startdate,
      :recurrence_days,
      :bev_rest_deleted,
      :delivery_instructions,
      :first_restaurant,
      :cutoff_hours,
      :cutoff_minutes,
      :admin_cutoff_hours,
      :admin_cutoff_minutes,
      :pickup_hours,
      :pickup_minutes,
      address_ids: [],
      cuisine_ids: [],
      tag_list: [],
      runningmenufields_attributes: [
        :id,
        :field_id,
        :fieldoption_id,
        :value
      ],
      recurring_dynamic_sections_attributes: [
        :id,
        :_destroy,
        :name,
        :icon,
        tag_list: []
      ]
    ]
  end

  index do
    column :id
    column 'DD&T', :startdate do |r|
      div do
        r.startdate_timezone.strftime('%a. %b %d %l:%M %P')
      end
    end

    column 'Meal' do |r|
      r.runningmenu_type&.capitalize.to_s + " " + r.menu_type&.capitalize.to_s
    end

    column "Company", :name, :sortable => 'companies.name' do |r|
      if r.company.deleted?
        span class: 'line-break' do
          link_to r.company.name, admin_company_path(r.company_id)
        end
        span class: 'line-break' do
          status_tag( :deleted )
        end
        span class: 'line-break address_wrap' do
          r.address.address_line
        end
      else
        span class: 'line-break' do
        link_to r.company.name, admin_company_path(r.company_id)
        end
        span class: 'line-break address_wrap' do
          address = r.address
          "#{address.street_number} "+ "#{address.street}, "+ "#{address.city}"
        end
      end
      span class: 'line-break' do
        r.delivery_instructions
      end
      span class: 'line-break' do
        r.address.short_code
      end
    end

    column 'Meeting' do |r|
      div class: 'hoverToolTip' do
        span link_to r.runningmenu_name&.capitalize.truncate(100, omission: ' ...'), admin_recurring_scheduler_path(r.id) if r.runningmenu_name.present?
        span class: "hoverData" do
          r.runningmenu_name&.capitalize
        end
      end

    end

    column 'Budget' do |r|
      if r.individual?
        r.scheduler_budget
      else
        nil
      end
    end

    column 'Driver', :first_name, :sortable => 'drivers.first_name' do |r|
      r.driver
    end

    # column :status, sortable: false do |runningmenu|
    #   status_tag( runningmenu.status.to_sym )
    # end
    # actions defaults: false do |scheduler|
    actions do |scheduler|
      if scheduler.parent_status_active?
        item('Delete', delete_admin_recurring_scheduler_path(scheduler.id), class: [:member_link, :delete_btn])
      elsif scheduler.parent_status_deleted? && scheduler.company.active?
        item('Activate', active_admin_recurring_scheduler_path(scheduler.id) , class: [:member_link, :active_btn])
      end
    end
  end

  show do
    attributes_table do
      row 'Meal Type' do |r|
        r.runningmenu_type
      end
      row 'Meeting Name' do |r|
        r.runningmenu_name
      end
      row 'Company Location' do |r|
        if r.address.deleted?
          span do
            r.address.name
          end
          span do
            status_tag( :deleted )
          end
        else
          r.address.name
        end
      end
      row 'Restaurants Location' do |r|
        raw(r.addresses.active.map(&:name).join("<br>"))
      end
      row 'Approximate Count' do |r|
        r.orders_count
      end
      if resource.individual?
        row 'Per Meal Budget' do |r|
          r.per_meal_budget
        end
        row 'User Copay' do |r|
          status_tag( r.per_user_copay? )
        end
        row 'Copay Amount($)' do |r|
          r.per_user_copay_amount
        end
      end
      # row :status do |runningmenu|
      #   status_tag( runningmenu.status.to_sym )
      # end
      row 'Cuisine Preference' do |r|
        raw(r.cuisines.map(&:name).join("<br>"))
      end
      row 'Special Requests' do |r|
        r.special_request
      end
      row 'Recurrence Days' do |r|
        r.recurrence_days
      end
      row 'Start Date & Time' do |r|
        r.startdate_timezone.strftime('%a. %b %d %l:%M %P')
      end
      unless params[:script_errors].blank?
        if params[:script_errors] == "success"
          row 'Script Report' do |r|
            status_tag( :success )
            " all meetings are created"
          end
        else
          row 'Script Report' do |r|
            status_tag( :failed )
            ("Following meetings are failed <br>, "+params[:script_errors]).gsub(", ","").html_safe
          end
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/recurring_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"RecurringScheduler").includes(:item)).sort_by(&:created_at).reverse}
      end

    end
  end

  form do |f|
    tabs do
      tab 'Schedular' do
        div class: "schedulerFirstTab" do
          div :class => "firstPageScheduler" do
            f.input :id, as: :hidden
            f.input :runningmenu_type, as: :select, collection: Runningmenu.runningmenu_types.keys.last(3), label: 'Meal Type'
            f.input :runningmenu_name, label: 'Meeting Name'
            f.input :menu_type, label: 'Menu Type', input_html: { disabled: f.object.approved?}
            f.input :address, label: 'Company Location', collection: Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id")
            # f.input :user_id, label: 'Company Admin', as: :select, collection: f.object.new_record? ? [] : resource.company.company_admins.active
            f.input :user_id, label: 'Company Admin', as: :select, collection: f.object.address.present? ? f.object.address.addressable.company_admins.active : []
            f.input :dynamic_sections_address_ids, as: :hidden, input_html: { value: f.object.addresses_recurring_schedulers.where("recurring_dynamic_section_id IS NOT NULL").pluck("address_id")}
            f.input :address_ids, as: :selected_list, url: runningmenu_addresses_admin_schedulers_path(recurring: true), width: "100%", minimum_input_length: 3, input_html: { class: 'restaurants_tags', multiple: true }, label: "Restaurants Location"#, hint: "Beverages & More will be added automatically."
            f.input :approve_ban_restaurant, label: "Schedule Anyway", as: :boolean if (f.object.errors.messages[:address_ids].present? && f.object.errors.messages[:address_ids].include?("The selected restaurant is on this company’s banned restaurant list")) || f.object.approve_ban_restaurant?
            f.input :cutoff_hours, input_html: { min: 0, step: 1}
            f.input :cutoff_minutes, input_html: { min: 0, step: 1}
            f.input :admin_cutoff_hours, input_html: { min: 0, step: 1}
            f.input :admin_cutoff_minutes, input_html: { min: 0, step: 1}
            f.input :pickup_hours, input_html: { min: 0, step: 1}
            f.input :pickup_minutes, input_html: { min: 0, step: 1}
          end
          div :class => "secondPageScheduler" do
            f.input :orders_count, label: 'Approximate Count'
            f.input :per_meal_budget, label: 'Per Meal Budget'
            f.input :per_user_copay, as: :boolean, label: 'Allow User Copay'
            f.input :per_user_copay_amount, label: 'Copay Amount($)'
            f.input :special_request, label: 'Special Requests', input_html: { class: 'special_request_text_area' }
            if f.object.new_record?
              cuisine = Cuisine.find_by_name("Pick for Me")
              f.object.cuisine_ids << cuisine.id if cuisine.present? && !f.object.cuisine_ids.include?(cuisine.id) 
              f.input :cuisine_ids, label: 'Cuisine Preference', as: :tags, collection: Cuisine.active.all 
            else
              f.input :cuisine_ids, label: 'Cuisine Preference', as: :tags, collection: Cuisine.active.all
            end
            f.input :delivery_instructions, input_html: {class: 'special_request_text_area'}
            f.input :selected_driver_id, as: :hidden, input_html: { value: f.object.driver&.id }
            f.input :driver_id, as: :select, collection: []
            f.input :bev_rest_deleted, as: :hidden, input_html: { value: false }
            f.input :first_restaurant, as: :hidden, input_html: { value: f.object.first_restaurant.nil? ? "" : f.object.first_restaurant }
            f.input :bev_rest_id, as: :hidden, input_html: { value: Restaurant.active.find_by_name(ENV['BEV_AND_MORE']).addresses.active.last&.id }
          end
        end
      end
      tab 'Schedular Fields' do
        div :id => "recurring_wrapper_fields" do
        end
      end
      tab 'Recurrence' do
        f.inputs do
          ol class: "wholeweek" do
            f.input :monday, as: :boolean
            f.input :tuesday, as: :boolean
            f.input :wednesday, as: :boolean
            f.input :thursday, as: :boolean
            f.input :friday, as: :boolean
            f.input :saturday, as: :boolean
            f.input :sunday, as: :boolean
          end
          # f.input :startdate, label: 'Start Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
        end
        # f.inputs do
        #   f.input :startdate, label: 'Start Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
        # end
        ol class: "start date" do
          f.input :startdate, label: 'Start Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
        end
        ol class: "days out" do
          f.input :recurrence_days, label: 'Recurrence Days', as: :select, collection: 1..30, selected: f.object.new_record? ? 30 : f.object.recurrence_days
        end
      end
      tab 'Restrictions' do
        f.input :hide_meeting, as: :boolean, label: 'Hide Meeting from Non-Admins'
        f.input :tag_list, as: :select, multiple: true, collection: ActsAsTaggableOn::Tag.for_tenant(f.object&.company_id).order(id: :asc).uniq.pluck(:name)
      end
      tab 'Dynamic Sections' do
        f.has_many :recurring_dynamic_sections, allow_destroy: true, heading: nil do |ds|
          ds.input :name
          ds.input :icon
          ds.input :tag_list, as: :select, multiple: true, collection: ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: {tenant: nil}).order(id: :asc).uniq.pluck(:name)
        end
      end
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  filter :id
  filter :runningmenu_type, label: 'Menu Type', as: :select, collection: -> {RecurringScheduler.runningmenu_types}
  filter :company_id, label: 'Company', as: :select, collection: proc{ Company.active }
  filter :address, label: 'Company Location', as: :select, collection: proc{ Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id") }
  filter :addresses, label: 'Restaurant Locations', as: :select, collection: proc{ Restaurant.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(restaurants.name,': ',addresses.address_line) as name, addresses.id") }
  filter :menu_type,label: 'Menu Type', as: :select, collection: -> {RecurringScheduler.menu_types}
  filter :monday
  filter :tuesday
  filter :wednesday
  filter :thursday
  filter :friday
  filter :saturday
  filter :sunday

  member_action :driver, method: :post do
    recurring_scheduler = RecurringScheduler.find params[:id]
    recurring_scheduler.driver_id = params[:driver_id]
    recurring_scheduler.save!
  end

  member_action :delete, method: :get do
    recurring_scheduler = RecurringScheduler.find(params[:id])
    if recurring_scheduler.parent_status_active?
      recurring_scheduler.update_column(:parent_status, RecurringScheduler.parent_statuses[:deleted])
      recurring_scheduler.update_column(:status, RecurringScheduler.statuses[:cancelled])
      redirect_to admin_recurring_schedulers_path, notice: "Recurring Schedular has been successfully deleted"
    end
  end

  member_action :active, method: :get do
    recurring_scheduler = RecurringScheduler.find(params[:id])
    recurring_scheduler.update_column(:parent_status, RecurringScheduler.parent_statuses[:active])
    if recurring_scheduler.addresses.active.present?
      recurring_scheduler.update_column(:status, RecurringScheduler.statuses[:approved])
    else
      recurring_scheduler.update_column(:status, RecurringScheduler.statuses[:pending])
    end
    redirect_to admin_recurring_schedulers_path, notice: "Scheduler haas been successfully active"
  end

  collection_action :company_time_zone_error_case, method: :get do
    startdate = nil
    company = Address.find(params[:company_address_id]).addressable
    startdate = params[:startdate].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    render json: { result: [startdate]}
  end

  controller do
    before_action :address_collection, only: [:edit, :update]
    before_action :set_paper_trail_whodunnit
    skip_around_action :set_admin_timezone
    def scoped_collection
      end_of_association_chain.includes([:company, :driver])
    end

    def edit
      resource.startdate = resource.startdate.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
    end

    def update
      if params['recurring_scheduler']['virtual_cuisine_ids_attr'].present?
        super
      else
        flash[:notice] = "Cuisines Cannot be empty"
        render :edit
      end
    end

    def create
      create! do |format|
        script_errors = resource.script_errors.blank? ? "success" : resource.script_errors
        format.html {redirect_to admin_recurring_scheduler_path(id: resource.id, script_errors: script_errors)} unless resource.errors.any?
      end
    end

    def address_collection
      @currentAddress = []
      currentAddressids = resource.addresses_recurring_schedulers.pluck(:address_id)
      currentAddressRunningmenu = RestaurantAddress.where(id: currentAddressids).map{|a| [a.name, a.id]}
      @menuAddresses = RestaurantAddress.active.distinct.joins(:menus, ' INNER JOIN restaurants ON addresses.addressable_id = restaurants.id').where.not(id: currentAddressids).pluck("CONCAT(restaurants.name ,': ', address_line)", :id)
      currentAddressRunningmenu.each do |a|
        @menuAddresses.push(a)
      end
      @allAddresses = @menuAddresses
    end

  end
end