ActiveAdmin.register Runningmenu, as: 'Scheduler' do

  menu parent: 'Schedulers', priority: 1
  config.batch_actions = false
  config.clear_action_items!
  config.sort_order = 'delivery_at_desc'
  actions :all, except: :destroy

  action_item :edit, only: [:show] do
    link_to 'Edit Schedular', edit_admin_scheduler_path(scheduler) if scheduler.delivery_at > Time.current
  end

  action_item :today, only: [:index] do
    link_to 'Today', admin_schedulers_path(q: {by_days_in: 'Today', top_filter: true}), class: 'linksForScope'
  end

  action_item :tomorrow, only: [:index] do
    link_to 'Tomorrow', admin_schedulers_path(q: {by_days_in: 'Tomorrow', top_filter: true}), class: 'linksForScope'
  end

  action_item :seven_days, only: [:index] do
    link_to '7 Days', admin_schedulers_path(q: {by_days_in: 'Next 7 Days', top_filter: true}), class: 'linksForScope'
  end

  action_item :thirty_days, only: [:index] do
    link_to '30 Days', admin_schedulers_path(q: {by_days_in: 'Next 30 Days', top_filter: true}), class: 'linksForScope'
  end

  action_item :show_all, only: [:index] do
    link_to 'Show All', admin_schedulers_path(q: {commit: 'clear_filters'}), class: 'linksForScope'
  end

  action_item :new, only: [:index] do
    link_to 'New Schedular', new_admin_scheduler_path
  end

  action_item :only => :index do
    link_to 'Bulk Schedule', admin_selected_schedules_upload_csv_path, class: 'bulk_schedule', for: 'uploadCSV_', remote: true
  end

  action_item :only => :index do
    link_to 'Download Sample', download_sample_csv_admin_schedulers_path, class: 'sampleFile_'
  end

  permit_params do
    permitted = [
      :runningmenu_type,
      :runningmenu_name,
      :address_id,
      :delivery_at,
      :activation_at,
      :cutoff_at,
      :admin_cutoff_at,
      :pickup_at,
      :special_request,
      :orders_count,
      :per_meal_budget,
      :per_user_copay,
      :per_user_copay_amount,
      :menu_type,
      :user_id,
      :hide_meeting,
      :restaurant_deleted,
      :deleted_restaurant_name,
      :driver_id,
      :approve_ban_restaurant,
      :submitted_from_backend,
      :bev_rest_deleted,
      :delivery_instructions,
      :delivery_type,
      :multiple_del_rests,
      address_ids: [],
      cuisine_ids: [],
      tag_list: [],
      runningmenufields_attributes: [
        :id,
        :field_id,
        :fieldoption_id,
        :value
      ],
      dynamic_sections_attributes: [
        :id,
        :_destroy,
        :name,
        :icon,
        tag_list: []
      ]
    ]
  end

  index do
    #column :id
    # column 'Comm. Detail' do |r|
    #   link_to "Detail", scheduler_detail_admin_scheduler_path(id: r.id), class: "commDash", remote: true
    # end
    column 'DD&T', :delivery_at, sortable: :delivery_at do |r|
      div do
        r.delivery_at_timezone.strftime('%a. %b %d %l:%M%P')
      end
      div class: 'hoverToolTip' do
        span do
          strong do
           "[i]"
          end
        end
        span class: "hoverData" do
          span do
            strong "Activation: "
            span r.activation_at_timezone.strftime('%a. %b %d %l:%M%P')
          end
          span class: 'line-break' do
            strong "Cutoff: "
            span r.cutoff_at_timezone.strftime('%a. %b %d %l:%M%P')
          end
          span class: 'line-break' do
            strong "Admin: "
            span r.admin_cutoff_at_timezone.strftime('%a. %b %d %l:%M%P')
          end
          span class: 'line-break' do
            strong "Pickup: "
            span r.pickup_at_timezone.strftime('%a. %b %d %l:%M%P')
          end
        end
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
        span link_to r.runningmenu_name&.capitalize.truncate(100, omission: ' ...'), admin_scheduler_path(r) if r.runningmenu_name.present?
        span class: "hoverData" do
          r.runningmenu_name&.capitalize
        end
      end

    end

    column 'Count' do |r|
      r.orders_count
    end

    column 'Budget' do |r|
      if r.individual?
        r.scheduler_budget
      else
        nil
      end
    end

    # column 'Rest.' do |r|
    #   render partial: 'admin/schedules/address_orders', locals: {runningmenu: r}
    # end

    column 'Rest. & Rest. Response' do |r|
      render partial: 'admin/schedules/address_runningmenu', locals: {addresses_runningmenus: r.addresses_runningmenus.joins(:address).where('addresses.alert_email = ?', false)}
    end

    column 'Driver', :first_name, :sortable => 'drivers.first_name' do |r|
      if (r.delivery_at > Time.current) && r.driver.present?
        render partial: 'admin/schedules/runningmenu_driver', locals: {driver: r.driver, runningmenu: r}
      else
        r.driver
      end
    end

    column :status, sortable: false do |runningmenu|
      status_tag( runningmenu.status.to_sym )
    end
    column :cutoff_reached_job_status, sortable: false do |runningmenu|
      status_tag( runningmenu.cutoff_reached_job_status.to_sym )
    end
    actions defaults: false do |scheduler|
      item 'Edit', edit_admin_scheduler_path(scheduler), class: :member_link if scheduler.delivery_at > Time.current || (scheduler.pending? && scheduler.delivery_at < Time.current)
      if scheduler.parent_status_active? && scheduler.company.active? && (scheduler.delivery_at > Time.current || (!scheduler.approved? && !scheduler.addresses.present?)) || (scheduler.pending? && scheduler.addresses.present?)
        item('Delete', delete_admin_scheduler_path(scheduler.id), class: [:member_link, :delete_btn])
      elsif scheduler.parent_status_deleted? && scheduler.company.active? && (scheduler.delivery_at > Time.current)
        item('Activate', active_admin_scheduler_path(scheduler.id) , class: [:member_link, :active_btn])
      end
      #item 'Order Summary', admin_order_report_path(s: scheduler.id, d: scheduler.delivery_at.to_date, c: scheduler.company_id, t: scheduler.runningmenu_type), class: :member_link if scheduler.approved?
      # item 'Cheat Sheet', cheat_sheet_admin_scheduler_path(scheduler.id,format: :pdf), class: :member_link, target: "_blank" if (scheduler.approved? && scheduler.company.enable_grouping_orders && scheduler.cutoff_at < Time.current && scheduler.orders.pluck(:group).compact.any?)
      item 'Cheat Sheet', cheat_sheet_admin_scheduler_path(scheduler.id,format: :pdf), class: :member_link, target: "_blank" if (scheduler.approved? && scheduler.cutoff_at < Time.current)
      item "Details", scheduler_detail_admin_scheduler_path(id: scheduler.id), class: [:member_link, :commDash], remote: true
      # company_admin = scheduler.company.company_admins.active.first
      # if company_admin.present? && company_admin.confirmed? && scheduler.delivery_at > Date.yesterday
      #   item('Login to frontend', login_admin_scheduler_path(id: company_admin.id, scheduler: scheduler), target: "_blank", class: :member_link)
      # end
    end
  end

  csv do
    column :id
    column 'Meeting Name' do |r|
      r.runningmenu_name
    end
    column 'Meal Type' do |r|
      r.runningmenu_type
    end
    column 'Company' do |r|
      r.company.name
    end
    column 'Company Location' do |r|
      r.address.address_line + ' ( ' + r.address.status + ' )'
    end
    column 'Restaurants Location' do |r|
      raw(r.addresses.map(&:name).join("<br>"))
    end
    column 'Approximate Count' do |r|
      #r.runningmenu_request.orders
      r.orders_count
    end
    column 'Delivery Date & Time' do |r|
      r.delivery_at_timezone
    end
    column 'Activation Date & Time' do |r|
      r.activation_at_timezone
    end
    column 'Cut Off Date & Time' do |r|
      r.cutoff_at_timezone
    end
    column 'Admin Cut Off Date & Time' do |r|
      r.admin_cutoff_at_timezone
    end
    column 'Pickup Date & Time' do |r|
      r.pickup_at_timezone
    end
    column 'Menu Type' do |r|
      r.menu_type
    end
  end

  form do |f|
    tabs do
      div id:'dialog-confirm', title: 'Are you sure?' do
      end
      tab 'Schedular' do
        div class: "schedulerFirstTab" do
          div :class => "firstPageScheduler" do
            f.input :id, as: :hidden
            f.input :runningmenu_type, as: :select, collection: Runningmenu.runningmenu_types.keys.last(3), label: 'Meal Type'
            f.input :runningmenu_name, label: 'Meeting Name'
            f.input :menu_type, label: 'Menu Type', input_html: { disabled: f.object.approved?}
            f.input :address, label: 'Company Location', collection: Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id")
            # f.input :user_id, input_html: { value: current_admin_user.id }, as: :hidden  if f.object.new_record?
            f.input :user_id, label: 'Company Admin', as: :select, collection: f.object.address.present? ? f.object.address.addressable.company_admins.active : []
            f.input :delivery_type, as: :select, collection: Runningmenu.delivery_types.keys, label: 'Delivery Type', include_blank: false
            f.input :dynamic_sections_address_ids, as: :hidden, input_html: { value: f.object.addresses_runningmenus.where("dynamic_section_id IS NOT NULL").pluck("address_id")}
            f.input :address_ids, as: :selected_list, url: runningmenu_addresses_admin_schedulers_path, width: "100%", minimum_input_length: 3, input_html: { class: 'restaurants_tags', multiple: true }, label: "Restaurants Location"#, hint: "Beverages & More will be added automatically."
            f.input :approve_ban_restaurant, label: "Schedule Anyway", as: :boolean if (f.object.errors.messages[:address_ids].present? && f.object.errors.messages[:address_ids].include?("The selected restaurant is on this company’s banned restaurant list")) || f.object.approve_ban_restaurant?
            f.input :delivery_at, label: 'Delivery Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
            f.input :pickup_at, label: 'Pickup Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
            f.input :activation_at, label: 'Activation Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
            f.input :cutoff_at, label: 'Cut Off Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
            f.input :admin_cutoff_at, label: 'Admin Cut Off Date & Time', as: :date_time_picker, input_html: { autocomplete: :off }
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
            f.input :selected_driver_id, as: :hidden, input_html: { value: f.object.driver&.id, name: f.object.driver&.name }
            f.input :driver_id, as: :select, collection: []
            # f.input :hide_meeting, as: :boolean, label: 'Hide Meeting from Non-Admins'
            f.input :submitted_from_backend, as: :hidden, input_html: { value: true }
            f.input :bev_rest_deleted, as: :hidden, input_html: { value: false }
            f.input :multiple_del_rests, as: :hidden, input_html: { value: false }
            f.input :bev_rest_id, as: :hidden, input_html: { value: Restaurant.active.find_by_name(ENV['BEV_AND_MORE']).addresses.active.last&.id }
          end
        end
      end
      tab 'Schedular Fields' do
        # if f.object.errors.present? && f.object.errors.messages.first[0].to_s == "runningmenufields.field_id"
        #   div :class => "flashes" do
        #     div :class => "flash flash_notice" do
        #       f.object.errors.messages.first[1].first
        #     end
        #   end
        # end

        if params[:runningmenu].present? && params[:runningmenu][:runningmenufields_attributes].present?
          r_counter = 0
          div :class => "wrapper_runningmenufields" do
            params[:runningmenu][:runningmenufields_attributes].values.each do |runningmenufields|
              r_field = Field.active.find_by_id(runningmenufields[:field_id])
              render partial: 'admin/runningmenufields/runningmenufield', locals: {id: runningmenufields[:id].present? ? runningmenufields[:id] : '', field: r_field, dropdown: r_field.dropdown? ? true : false, fieldoption: r_field.dropdown? ? Fieldoption.find_by_id(runningmenufields[:fieldoption_id]) : '', text: r_field.text? ? true : false, value: r_field.text? ? runningmenufields[:value] : '', counter: r_counter}
              r_counter = r_counter + 1
            end
          end
        else
          div :id => "wrapper_fields" do
          end
        end
      end
      # tab 'Buffet Settings' do
      #   f.input :entree, input_html: { min: '0', step: '1', onclick: "this.select();"}
      #   f.input :appetizers, input_html: { min: '0', step: '1', onclick: "this.select();" }
      #   f.input :dessert, input_html: { min: '0', step: '1', onclick: "this.select();" }
      #   f.input :sides, input_html: { min: '0', step: '1', onclick: "this.select();" }
      #   f.input :buffet_per_user_budget, input_html: { min: '0', step: '0.01', onclick: "this.select();" }
      # end
      tab 'Restrictions' do
        f.input :hide_meeting, as: :boolean, label: 'Hide Meeting from Non-Admins'
        f.input :tag_list, as: :select, multiple: true, collection: ActsAsTaggableOn::Tag.for_tenant(f.object&.company_id).order(id: :asc).uniq.pluck(:name)
      end
      tab 'Dynamic Sections' do
        f.has_many :dynamic_sections, allow_destroy: true, heading: nil do |ds|
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
    # render partial: '/active_admin/schedules/restaurants'
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
      row 'Delivery Date & Time' do |r|
        r.delivery_at_timezone
      end
      row 'Pickup Date & Time' do |r|
        r.pickup_at_timezone
      end
      row 'Activation Date & Time' do |r|
        r.activation_at_timezone
      end
      row 'Cut Off Date & Time' do |r|
        r.cutoff_at_timezone
      end
      row 'Admin Cut Off Date & Time' do |r|
        r.admin_cutoff_at_timezone
      end
      row :status do |runningmenu|
        status_tag( runningmenu.status.to_sym )
      end
      row 'Cuisine Preference' do |r|
        raw(r.cuisines.map(&:name).join("<br>"))
      end
      row "Cancellation Reason" do |r|
        r.cancel_reason
      end
      row "Cancelled By" do |r|
        r.cancelled_by
      end
      row "Cancelled At" do |r|
        r.cancelled_at
      end
      row 'Special Requests' do |r|
        r.special_request
      end
      row :delivery_type
      row 'Rejected by vendor' do |r|
        r.addresses_runningmenus.where(rejected_by_vendor: true).each do |ra|
          div do
            "#{ra.address.addressable.name}: #{ra.reject_reason}"
          end
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/runningmenu_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Runningmenu").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  # member_action :login, method: :get do
  #   runningmenu = Runningmenu.find params[:scheduler]
  #   user = User.find(params[:id])
  #   user.frontend_login_token = rand(36**32).to_s(36)
  #   user.save
  #   redirect_to ENV['FRONTEND_HOST'] + '/admin-login/' + user.frontend_login_token + '?delivery_at=' + runningmenu.delivery_at.strftime("%m-%d-%Y") + '&meeting_id=' + runningmenu.id.to_s
  # end

  collection_action :runningmenu_addresses, method: :get do
    enable_self_service = (cookies["delivery_type"].present? && cookies["delivery_type"] == "delivery" && params["recurring"].blank?) ? true : false
    if cookies["menu_type"].present? && cookies["menu_type"] == "individual"
      addresses = RestaurantAddress.active.distinct.joins(:menus, ' INNER JOIN restaurants ON addresses.addressable_id = restaurants.id').where("restaurants.name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%").where("addresses.enable_self_service = ?", enable_self_service)
      render json: addresses.collect {|address| {:id => address.id, :name => address.name} }
    else
      addresses = RestaurantAddress.active.distinct.joins(:menu_buffet, ' INNER JOIN restaurants ON addresses.addressable_id = restaurants.id').where("restaurants.name ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%").where("addresses.enable_self_service = ?", enable_self_service)
      render json: addresses.collect {|address| {:id => address.id, :name => address.name} }
    end
  end

  collection_action :runningmenu_beverages_restaurant, method: :get do
    restaurant = Restaurant.active.find_by_name(ENV['BEV_AND_MORE'])
    beverages_restaurant = ""
    if restaurant.present?
      address = restaurant.addresses.active.last
      if params[:addresses].blank?
        beverages_restaurant = "<div id=runningmenu_address_ids_#{address.id} class='selected-item'>#{address.name}<input id='runningmenu_address_ids_#{address.id}' name='runningmenu[address_ids][]' value='#{address.id}' type='hidden'></div>"
      else
        params[:addresses].scan(/\d+/).map(&:to_i).each do |addr_id|
          address = Address.find_by_id(addr_id)
          beverages_restaurant << "<div class='selected-item' id='runningmenu_address_ids_#{address.id}'>#{address.name}<input name='runningmenu[address_ids][]' type='hidden' value='#{address.id}'></div>"
        end
      end
    end
    render json: {str_html: beverages_restaurant }
  end

  collection_action :recurring_runningmenu_beverages_restaurant, method: :get do
    restaurant = Restaurant.active.find_by_name(ENV['BEV_AND_MORE'])
    beverages_restaurant = ""
    beverages_restaurant_location_id = ""
    if restaurant.present?
      address = restaurant.addresses.active.last
      if params[:addresses].blank?
        beverages_restaurant = "<div id=recurring_scheduler_address_ids_#{address.id} class='selected-item'>#{address.name}<input id='recurring_scheduler_address_ids_#{address.id}' name='recurring_scheduler[address_ids][]' value='#{address.id}' type='hidden'></div>"
      else
        params[:addresses].scan(/\d+/).map(&:to_i).each do |addr_id|
          address = Address.find_by_id(addr_id)
          beverages_restaurant << "<div class='selected-item' id='recurring_scheduler_address_ids_#{address.id}'>#{address.name}<input name='recurring_scheduler[address_ids][]' type='hidden' value='#{address.id}'></div>"
        end
      end
    end
    render json: {str_html: beverages_restaurant, beverages_restaurant_location_id: address.id}
  end

  collection_action :runningmenu_beverages_restaurant_has_buffet_menu, method: :get do
    restaurant = Restaurant.active.find_by_name(ENV['BEV_AND_MORE'])
    beverages_restaurant = false
    if restaurant.present?
      beverages_restaurant = restaurant.addresses.active.last.menu_buffet.present?
    end
    render json: {str_html: beverages_restaurant }
  end

  collection_action :restaurant_cutoffs, method: :get do
    restaurant_address = RestaurantAddress.find_by_id(params[:restaurant_address_id])
    individual_meals_cutoff, buffet_cutoff = 22, 48
    if restaurant_address.present?
      individual_meals_cutoff, buffet_cutoff = restaurant_address.individual_meals_cutoff, restaurant_address.buffet_cutoff
    end
    render json: {individual_meals_cutoff: 3.6e+6*individual_meals_cutoff, buffet_cutoff: 3.6e+6*buffet_cutoff }
  end

  collection_action :company_admins do
    data = ''
    #runningmenu = Runningmenu.find_by_id params[:id].to_i
    company_address = CompanyAddress.find params[:company_address_id]
    # if runningmenu
    #   company_address.addressable.company_admins.active.each do |company_admin|
    #     if company_admin.id == runningmenu.user_id
    #       data = data + "<option selected='selected' value='#{company_admin.id}'>#{company_admin.name}</option>"
    #     else
    #       data = data + "<option value='#{company_admin.id}'>#{company_admin.name}</option>"
    #     end
    #   end
    # else
      company_address.addressable.company_admins.active.each do |company_admin|
        if company_admin.id == company_address.default_admin&.id
          data = data + "<option selected='selected' value='#{company_admin.id}'>#{company_admin.name}</option>"
        else
          data = data + "<option value='#{company_admin.id}'>#{company_admin.name}</option>"
        end
      end
    # end
    render json: {data: data }
  end

  collection_action :company_delivery_notes do
    data = ""
    runningmenu = params[:type].present? && params[:type] == 'recurring' ? RecurringScheduler.find(params[:id]) : Runningmenu.find(params[:id]) rescue nil
    company_address = CompanyAddress.find params[:company_address_id]
    notes = company_address.addressable.delivery_notes
    data = "<li class='text input optional delivery_notes_li''><label class='label'>Delivery Notes</label><div rows='20' class='delivery_notes_text_area'>#{notes}</div></li>" unless notes.blank?
    delivery_instructions = runningmenu.blank? ? company_address.delivery_instructions : company_address.id == runningmenu.address_id ? runningmenu.delivery_instructions : company_address.delivery_instructions
    render json: {data: data, delivery_instructions: delivery_instructions }
  end

  collection_action :shifts_available do
    delivery_date = params[:delivery_at].to_datetime.to_date
    delivery_time = params[:delivery_at].to_datetime.strftime('%H:%M:%S')
    time_zone = Address.find(params[:address_id]).addressable.time_zone
    addresses = RestaurantAddress.joins("LEFT JOIN holidays ON holidays.address_id = addresses.id AND '#{delivery_date}' BETWEEN holidays.start_date AND holidays.end_date").joins("LEFT JOIN restaurant_shifts ON restaurant_shifts.address_id = addresses.id AND '#{delivery_time}' BETWEEN (restaurant_shifts.start_time AT TIME ZONE '#{time_zone}')::time AND (restaurant_shifts.end_time AT TIME ZONE '#{time_zone}')::time").where("addresses.id IN (#{params[:address_ids]}) AND (holidays.id IS NOT NULL OR restaurant_shifts.id IS NULL)").uniq
    str = "<b>Restaurants are not available!</b><ul class='addresses-ul'>"
    show_dialog = false
    addresses.collect{|a| a.name }.each do |rest_name|
      show_dialog = true
      str += "<li>#{rest_name}</li>"
    end
    str += "</ul>"
    render json: { addresses: str, show_dialog: show_dialog }
  end

  collection_action :recurrence_schedulers, method: :post do
    if params[:from].present? && params[:to].present? && params[:company_id].present?
      start_date = Date.strptime(params[:from], "%m/%d/%Y")
      end_date = Date.strptime(params[:to], "%m/%d/%Y")
      errors = []
      runningmenu_ids = []
      error_msg = nil
      company = Company.find params[:company_id]
      company.recurring_schedulers.where.not(status: :cancelled).each do |recurring_scheduler|
        (start_date..end_date).each do |d|
          date_zone = d.in_time_zone(company.time_zone)
          if recurring_scheduler[date_zone.strftime("%A").downcase.to_sym]
            arr = recurring_scheduler.generate_scheduler_call(date_zone, recurring_scheduler)
            errors << arr[0]
            runningmenu_ids << arr[1]
          end
        end
      end
      error_msg = errors.compact.join("") unless errors.compact.blank?
      runningmenu_ids = runningmenu_ids.compact
      if runningmenu_ids.present? && error_msg.blank?
        redirect_to admin_manual_schedulers_path(runningmenu_ids: runningmenu_ids), notice: "Schedulers have been successfully generated"
      elsif runningmenu_ids.present? && error_msg.present?
        redirect_to admin_manual_schedulers_path(runningmenu_ids: runningmenu_ids), notice: "Some Schedulers not created due to #{error_msg}"
      elsif error_msg.present?
        redirect_to admin_recurring_schedulers_path, alert: error_msg
      else
        redirect_to admin_invoices_path, alert: "No templates found to generate schedulers"
      end
    else
      redirect_to admin_manual_schedulers_path, alert: "All fields are required in order to create schedulers."
    end
  end

  collection_action :recurring_company_admins do
    data = ''
    #recurring_scheduler = RecurringScheduler.find_by_id params[:id].to_i
    company_address = CompanyAddress.find params[:company_address_id]
    # if recurring_scheduler
    #   company_address.addressable.company_admins.active.each do |company_admin|
    #     if company_admin.id == recurring_scheduler.user_id
    #       data = data + "<option selected='selected' value='#{company_admin.id}'>#{company_admin.name}</option>"
    #     else
    #       data = data + "<option value='#{company_admin.id}'>#{company_admin.name}</option>"
    #     end
    #   end
    # else
      company_address.addressable.company_admins.active.each do |company_admin|
        if company_admin.id == company_address.default_admin&.id
          data = data + "<option selected='selected' value='#{company_admin.id}'>#{company_admin.name}</option>"
        else
          data = data + "<option value='#{company_admin.id}'>#{company_admin.name}</option>"
        end
      end
    # end
    render json: {data: data }
  end

  member_action :delete, method: :get do
    runningmenu = Runningmenu.find(params[:id])
    if runningmenu.parent_status_active?
      runningmenu.update_column(:parent_status, Runningmenu.parent_statuses[:deleted])
      runningmenu.update_column(:status, Runningmenu.statuses[:cancelled])
      runningmenu.update_column(:cancelled_at, Time.current)
      runningmenu.send_email_for_cancel_schedule
      runningmenu.driver&.cancelled_meeting(runningmenu)
      redirect_to admin_schedulers_path, notice: "Scheduler has been successfully deleted"
    end
    runningmenu.orders.each do |order|
      order.update_column(:status, Order.statuses[:cancelled])
    end
  end

  member_action :scheduler_detail, method: :get do
    respond_to do |format|
      format.js do
        render "/admin/schedules/sidebar", :locals => {:type => params[:id], :format => [:js]}
      end
    end
  end

  member_action :active, method: :get do
    runningmenu = Runningmenu.find(params[:id])
    runningmenu.update_column(:parent_status, Runningmenu.parent_statuses[:active])
    runningmenu.update_column(:cancelled_at, nil)
    if runningmenu.addresses.active.present?
      runningmenu.update_columns(status: Runningmenu.statuses[:approved], approved_at: Time.current)
      runningmenu.init_notify_restaurant_job
    else
      runningmenu.update_column(:status, Runningmenu.statuses[:pending])
    end
    runningmenu.orders.each do |order|
      if order.parent_status_deleted?
        order.update_column(:status, Order.statuses[:cancelled])
        runningmenu.update_column(:cancelled_at, Time.current)
      else
        order.update_column(:status, Order.statuses[:active])
      end
    end
    redirect_to admin_schedulers_path, notice: "Scheduler haas been successfully active"
  end

  member_action :cheat_sheet, method: :get do
    runningmenu = Runningmenu.find params[:id]
    orders = runningmenu.orders.active
    total_items = orders.sum(:quantity).to_i
    respond_to do |format|
      format.pdf do
        render pdf: "#{runningmenu.company.name.gsub(" ","-").downcase}-cheat_sheet-#{runningmenu.delivery_at_timezone.strftime('%a, %d %b %Y %H:%M:%S')}", template: 'admin/schedules/cheat_sheetpdf.html.erb', locals: { orders: orders, runningmenu: runningmenu, grouped_orders: runningmenu.grouped_orders, ungrouped_orders: runningmenu.ungrouped_orders , total_items: total_items }
      end
    end

  end

  member_action :acknowledge_schedule, method: :post do
    addresses_runningmenu = AddressesRunningmenu.find params[:id]

    if params[:status].present? && params[:status] == "no_response"
      addresses_runningmenu.receipt_declined!
      addresses_runningmenu.orders_declined!
      addresses_runningmenu.changes_declined!
      render json: {message: "success"}
    elsif params[:status].present? && params[:status] == "ack_schedule"
      addresses_runningmenu.receipt_acknowledge!
      render json: {message: "success"}
    elsif params[:status].present? && params[:status] == "accept_orders"
      addresses_runningmenu.orders_acknowledge!
      render json: {message: "success"}
    elsif params[:status].present? && params[:status] == "accept_modification"
      addresses_runningmenu.changes_acknowledge!
      render json: {message: "success"}
    end
  end

  member_action :driver, method: :post do
    runningmenu = Runningmenu.find params[:id]
    runningmenu.driver_id = params[:driver_id]
    runningmenu.skip_set_dates = true
    runningmenu.save!
  end

  # member_action :chat, method: :post do
  #   runningmenu = Runningmenu.find params[:id]
  #   from = ENV["SMS_FROM"]
  #   to = ENV["SMS_TO"]
  #   # to = Onfleet::Worker.get(runningmenu.driver.worker_id).phone
  #   message = params[:message]
  #   begin
  #     # @client = Twilio::REST::Client.new(ENV["TWILIO_TEST_ACCOUNT_SID"], ENV["TWILIO_TEST_AUTH_TOKEN"])
  #     # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  #     sms = $twilio_client.messages.create(body: message,from: from,to: to)
  #     render json: {message: "<div class='message'><span class='user'><strong>#{from}: </strong></span>#{message}</div></br>"}
  #   rescue => e
  #     puts e.message
  #     render json: {message: "<div class='message'><span class='user'><strong>#{from}: </strong></span>Message not sent #{e.message}</div>"}
  #   end
  # end

  collection_action :chat_history, method: :get do
    if admin_user_signed_in?
      admin_number = ENV["SMS_FROM"]
      driver_number = Driver.find(params["driver"]).number_at_onfleet
      # @client = Twilio::REST::Client.new(ENV["TWILIO_TEST_ACCOUNT_SID"], ENV["TWILIO_TEST_AUTH_TOKEN"])
      # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
      messages = []
      to_admin_msgs = $twilio_client.messages.list(to: admin_number, from: driver_number, limit: 20).reverse
      to_driver_msgs = $twilio_client.messages.list(to: driver_number, from: admin_number, limit: 20).reverse
      (to_admin_msgs+to_driver_msgs).sort_by{|m| m.date_sent}.last(20).each do |message|
        if driver_number == message.from
          messages << "<div class='driver'><span>Driver: </span>#{message.body}</div>"
        else
          messages << "<div class='me'><span>me: </span>#{message.body}</div>"
        end
      end
      render json: {message: messages.join("")}
    else
      render json: {message: ""}
    end
  end

  collection_action :download_sample_csv, method: :get do
    send_file(
      "#{Rails.root}/app/assets/csvs/sample_bulk_schedulers.csv",
      filename: "sample_bulk_schedulers.csv",
      type: "text/csv",
      disposition: 'attachment'
    )
  end

  collection_action :runningmenu_restaurant_locations, method: :get do
    restaurant_locations =  Restaurant.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(restaurants.name,': ',addresses.address_line) as name, addresses.id").where("addresses.address_line ILIKE :prefix", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: restaurant_locations.collect {|restaurant_location| {:id => restaurant_location.id, :name => restaurant_location.name} }
  end

  # collection_action :fax_pdf, method: :get do
  #   # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  #   address = RestaurantAddress.find_by_id(params[:restaurant_address_id])
  #   FileUtils.mkdir_p 'public/fax_summary'
  #   orders = []
  #   user = false
  #   scheduler = Runningmenu.find_by_id params[:s]
  #   delivery_at = scheduler.delivery_at
  #   orders = Order.order_summary(scheduler, true, 0, 0, params[:restaurant_address_id].to_i)
  #   file_path = "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf"
  #   ac = ActionController::Base.new()
  #   template_path = params[:buffet].present? && params[:buffet] == "true" ? "admin/orders/buffetsummarypdf.html.erb" : "admin/orders/ordersummarypdf.html.erb"
  #   pdf = ac.render_to_string pdf: file_path, template: template_path, locals: { orders: orders, delivery_at: scheduler.delivery_at_timezone, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p"), fax: true, runningmenu: scheduler, address_id: params[:restaurant_address_id]}, disposition: 'attachment', encoding: "UTF-8"
  #   save_path = Rails.root.join('public','fax_summary', file_path)
  #   File.open(save_path, 'wb') do |file|
  #     file << pdf
  #   end
  #   s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
  #   bucket_name = ENV['S3_BUCKET_NAME']
  #   @key = "pdf/#{file_path}"
  #   @s3_obj = s3.bucket(bucket_name).object(@key)
  #   File.open(save_path, 'rb') do |file|
  #     @s3_obj.put(body: file, acl: 'public-read')
  #   end
  #   # pdf_url = @s3_obj.presigned_url(:get)
  #   pdf_url_key = @s3_obj.key
  #   File.delete(save_path) if File.exist?(save_path)
  #   begin
  #     if Rails.env.production?
  #       fax = $twilio_client.fax.faxes.create(from: ENV['SMS_FROM'],to: "+1#{address.contacts.where.not(fax: "")&.last&.fax.split("-").join()}", media_url: ENV["S3_BUCKET_URL"]+"/"+pdf_url_key, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_fax_status/webhook")
  #       if fax.sid.present?
  #         Faxlog.create(from: fax.from, to: fax.to, sid: fax.sid, media_url: pdf_url_key, status: Faxlog.statuses["pending"], file_name: file_path.split("-").last(2).first+Time.now.strftime('-%a, %d %b %H:%M:%S.pdf'), tries: 1)
  #         redirect_to admin_schedulers_path, notice: "Fax sent successfully."
  #       end
  #     else
  #       redirect_to admin_schedulers_path, notice: "Fax sent successfully."
  #     end
  #   rescue StandardError => e
  #     redirect_to admin_schedulers_path, notice: "Fax failed due to #{e.message}"
  #   end
  # end

  filter :id
  filter :by_days_in, label: 'Upcoming Deliveries', :as => :select, collection: ["Today", "Tomorrow", "Next 7 Days", "Next 30 Days"]
  filter :runningmenu_type, label: 'Menu Type', as: :select, collection: -> {Runningmenu.runningmenu_types}
  # filter :company_id, label: 'Company', as: :select, collection: proc{ Company.active.where(:id=>Runningmenu.pluck(:company_id).uniq).pluck(:name, :id) }
  # filter :address, label: 'Company Location', as: :select, collection: proc{ CompanyAddress.active.where(:id=>Runningmenu.pluck(:address_id).uniq).pluck(:address_line, :id) }
  # filter :addresses, label: 'Restaurant Locations', as: :select, collection: proc{ RestaurantAddress.active.where(:id=>Runningmenu.joins(:addresses).pluck("addresses.id").uniq).pluck(:address_line, :id) }
  # filter :company_id, label: 'Company', as: :select, collection: proc{ Company.active }
  filter :company_id, as: :search_select_filter, url: proc {  companies_admin_companies_path

 }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'


  filter :address_id, label: 'Company Location', as: :search_select_filter, url: proc { company_addresses_admin_companies_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'

  filter :user_id, input_html: {name: 'q[addresses_runningmenus_address_id_eq]'}, label: 'Restaurant Locations', as: :search_select_filter, url: proc { runningmenu_restaurant_locations_admin_schedulers_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'

  # filter :address, label: 'Company Location', as: :select, collection: proc{ Company.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(companies.name,': ',addresses.address_line) as name, addresses.id") }
  # filter :addresses, label: 'Restaurant Locations', as: :select, collection: proc{ Restaurant.active.joins(:addresses).where("addresses.status = ?", Address.statuses[:active]).select("CONCAT(restaurants.name,': ',addresses.address_line) as name, addresses.id") }
  filter :status,label: 'Status', as: :select, collection: -> {Runningmenu.statuses}
  filter :menu_type,label: 'Menu Type', as: :select, collection: -> {Runningmenu.menu_types}
  filter :delivery_at,label: 'Delivery Time', as: :date_range
  filter :pickup_at,label: 'Pickup Time', as: :date_range
  filter :activation_at,label: 'Activation Time', as: :date_range
  filter :cutoff_at,label: 'Cutoff Time', as: :date_range
  filter :admin_cutoff_at,label: 'Admin Cutoff Time', as: :date_range

  collection_action :company_time_zone_error_case, method: :get do
    delivery_at = pickup_at = activation_at = cutoff_at = admin_cutoff_at = nil
    company = Address.find(params[:company_address_id]).addressable
    delivery_at = params[:delivery_at].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    pickup_at = params[:pickup_at].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    activation_at = params[:activation_at].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    cutoff_at = params[:cutoff_at].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    admin_cutoff_at = params[:admin_cutoff_at].to_datetime.in_time_zone(company.time_zone).strftime("%Y-%m-%d %H:%M")
    render json: { result: [delivery_at, pickup_at, activation_at, cutoff_at, admin_cutoff_at]}
  end

  collection_action :available_list, method: :get do
    drivers = []
    Driver.available_on(params[:delivery_at], params[:pickup_at], params[:delivery_type], params[:address_id], params[:address_ids]).each do |d|
      drivers.push({id: d.id, first_name: d.first_name, last_name: d.last_name})
    end
    render json: { drivers: drivers}
  end

  collection_action :recurring_available_list, method: :get do
    drivers = []
    Driver.active.where(restaurant_address_id: nil).each do |d|
      drivers.push({id: d.id, first_name: d.first_name, last_name: d.last_name})
    end
    render json: { drivers: drivers}
  end

  collection_action :user_meal_budget, method: :get do
    budget = Company.user_meal_budget.where('company_id = ?', params[:q][:comp_id_eq])
  end

  controller do
    skip_before_action :verify_authenticity_token, :only => [:acknowledge_schedule, :driver, :chat, :chat_history, :upload_csv, :update_imported_schedules]
    skip_around_action :set_admin_timezone, except: [:index]
    before_action :set_paper_trail_whodunnit
    after_action :check_deleted_restaurant, only: [:update]

    def index
      params[:q][:by_days_in] = params[:q][:by_days_in] +"--"+current_admin_user.time_zone unless params[:q][:by_days_in].nil? rescue nil
      super
    end

    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    def scoped_collection
      end_of_association_chain.includes([:company, :driver])
    end

    def create
      if params["runningmenu"]["delivery_type"] == "delivery" && params["runningmenu"]["address_ids"].count > 2
        params["runningmenu"]["multiple_del_rests"] = true
      end
      super
    end

    def edit
      resource.delivery_at = resource.delivery_at.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
      resource.pickup_at = resource.pickup_at.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
      resource.activation_at = resource.activation_at.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
      resource.cutoff_at = resource.cutoff_at.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
      resource.admin_cutoff_at = resource.admin_cutoff_at.in_time_zone(resource.company.time_zone).strftime("%a, %d %B %Y %H:%M:%S")
    end

    def update
      if params['runningmenu']['virtual_cuisine_ids_attr'].present?
        if (params["runningmenu"]["delivery_type"] == "delivery" && params["runningmenu"]["address_ids"].count > 2) || (params["runningmenu"]["delivery_type"] == "pickup" && resource.delivery? && resource.orders.active.present?)
          params["runningmenu"]["multiple_del_rests"] = true
          params["runningmenu"]["address_ids"] = [""]+resource.address_ids.map{|m| m.to_s}
        elsif (params["runningmenu"]["delivery_type"] == "delivery" && resource.pickup? && resource.orders.active.present?)
          params["runningmenu"]["address_ids"] = [""]+resource.address_ids.map{|m| m.to_s}
        end
        super
      else
        flash[:notice] = "Cuisines Cannot be empty"
        render :edit
      end
    end

    def check_deleted_restaurant
      if resource.restaurant_deleted
        flash.clear
        flash[:alert] = "The restaurant #{resource.deleted_restaurant_name} has active orders, therefore, it cannot be removed from this scheduler. Please cancel active orders before removing restaurant."
      end
    end

  end
end
