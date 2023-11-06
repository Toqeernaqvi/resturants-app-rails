ActiveAdmin.register Address, as: 'Address' do
  menu false
  config.batch_actions = false
  breadcrumb do
     if request.params[:action] == "edit"
       [link_to('Restaurant', admin_restaurants_path),link_to("#{resource.present? ? resource.addressable.id : params[:restaurant_id]}", admin_restaurant_path(resource.present? ? resource.addressable.id : params[:restaurant_id])), link_to('Addresses', admin_restaurant_addresses_path(resource.present? ? resource.addressable.id : params[:restaurant_id])), link_to("#{params[:id]}", admin_restaurant_address_path(resource.present? ? resource.addressable.id : params[:restaurant_id], params[:id]))]
     elsif request.params[:action] == "show"
       [link_to('Restaurant', admin_restaurants_path),link_to("#{resource.present? ? resource.addressable.id : params[:restaurant_id]}", admin_restaurant_path(resource.present? ? resource.addressable.id : params[:restaurant_id])), link_to('Addresses', admin_restaurant_addresses_path(resource.present? ? resource.addressable.id : params[:restaurant_id])), params[:id]]
     else
       [link_to('Restaurant', admin_restaurants_path),link_to("#{params[:restaurant_id].present? ? params[:restaurant_id] : resource.addressable.id}", admin_restaurant_path(params[:restaurant_id].present? ? params[:restaurant_id] : resource.addressable.id))]
     end
  end
  actions :all, except: :destroy

  permit_params do
    permitted = [
      :address_line,
      :time_zone,
      :address_name,
      :suite_no,
      :street_number,
      :street,
      :city,
      :state,
      :zip,
      :longitude,
      :latitude,
      :delayed_payout_days,
      :discount_percentage,
      :lunch_order_capacity,
      :dinner_order_capacity,
      :notes,
      :alert_email,
      :add_contract_commission,
      :items_count,
      :buffet_commission,
      :minimum_discount_price,
      :enable_marketplace,
      :enable_self_service,
      :delivery_radius,
      :delivery_cost,
      :individual_meals_cutoff,
      :buffet_cutoff,
      :minimum_order_quantity,
      :random_menu_images,
      :logo,
      dishsizes_attributes: [
        :id,
        :_destroy,
        :title,
        :description,
        :serve_count,
        :parent_status
      ],
      contacts_attributes: [
        :id,
        :_destroy,
        :name,
        :phone_number,
        :send_text_reminders,
        :email,
        :email_summary_check,
        :email_label_check,
        :fax,
        :fax_summary_check
      ],
      monday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      tuesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      wednesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      thursday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      friday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      saturday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      sunday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :closed,
        :time_zone,
        :_destroy
      ],
      images_attributes: [
        :id,
        :_destroy,
        :image
      ],
      holidays_attributes: [
        :id,
        :_destroy,
        :start_date,
        :end_date,
      ]
      # ,
      # restaurant_admin_attributes: [
      #   :id,
      #   :_destroy,
      #   :email,
      #   :first_name,
      #   :last_name
      # ]
    ]
  end

  index do
    column :id
    column ("Name") {|a| a.address_name}
    column ("Address") {|a| a.address_line}
    column ("Payout (days)") {|a| a.delayed_payout_days}
    column ("Commission ( % )") {|a| a.discount_percentage}
    column ("Lunch Capacity") {|a| a.lunch_order_capacity}
    column ("Dinner Capacity") {|a| a.dinner_order_capacity}
    column ("Contact Name") {|a| mail_to (a.contacts.present? && a.contacts.first.email.present?) ? a.contacts.first.email : ""}
    # column ("Per User Buffet Price") {|a| a.buffet_price}
    actions do |address|
      if address.active?
        item('Delete', delete_admin_address_path(address.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_address_path(address.id) , class: [:member_link, :active_btn])
      end
      if address.menu_breakfast.present? && address.menu_breakfast.active?
        (item 'Breakfast Menu', edit_admin_restaurant_address_menu_path(address_id: address.id, id: address.menu_breakfast.id), class: :member_link)
      else
        (item 'Breakfast Menu', new_admin_restaurant_address_menu_path(address_id: address.id, type: 'breakfast'), class: :member_link )
      end
      if address.menu_lunch.present? && address.menu_lunch.active?

        (item 'Lunch Menu', edit_admin_restaurant_address_menu_path(address_id: address.id, id: address.menu_lunch.id), class: :member_link)
      else
        (item 'Lunch Menu', new_admin_restaurant_address_menu_path(address_id: address.id, type: 'lunch'), class: :member_link)
      end
      if address.menu_dinner.present? && address.menu_dinner.active?
        (item 'Dinner Menu', edit_admin_restaurant_address_menu_path(address_id: address.id, id: address.menu_dinner.id), class: :member_link)
      else
        (item 'Dinner Menu', new_admin_restaurant_address_menu_path(address_id: address.id, type: 'dinner'), class: :member_link)
      end
      if address.menu_buffet.present? && address.menu_buffet.active?
        (item 'Buffet Menu', edit_admin_restaurant_address_menu_path(address_id: address.id, id: address.menu_buffet.id), class: :member_link)
      else
        (item 'Buffet Menu', new_admin_restaurant_address_menu_path(address_id: address.id, type: 'buffet'), class: :member_link)
      end
    end
  end

  csv do
    column :id
    column :address_line
    column :delayed_payout_days
    column :discount_percentage
    column :lunch_order_capacity
    column :dinner_order_capacity
    # column :buffet_price
  end

  form do |f|
    rand_ = 1;
    tabs do
      tab "Address" do
        f.inputs do
          f.input :address_line, label: "Address", input_html: {id: "autocomplete_#{rand_}", onFocus: 'geolocate(this);', autocomplete: :off}, :placeholder => 'Enter Your Address'
          # f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone::MAPPING.collect {|k, v| [k,v]}
          f.input :suite_no, label: "Suite Number"
          f.input :address_name, label: "Name", :placeholder => 'Enter Name'
          f.input :street_number, :input_html =>{:id => "street_number_#{rand_}"}, :as => :hidden
          f.input :street, :input_html =>{:id => "route_#{rand_}"}, :as => :hidden
          f.input :city, :input_html =>{:id => "locality_#{rand_}"}, :as => :hidden
          f.input :state, :input_html =>{:id => "administrative_area_level_1_#{rand_}"}, :as => :hidden
          f.input :zip, :input_html =>{:id => "postal_code_#{rand_}"}, :as => :hidden
          f.input :longitude, :input_html =>{:id => "longitude_#{rand_}"}, :as => :hidden
          f.input :latitude, :input_html =>{:id => "latitude_#{rand_}"}, :as => :hidden
          f.input :delayed_payout_days, as: :select, collection: 6..30, label: "Payout (days)", include_blank: false
          f.input :discount_percentage, label: "Commission ( % )"
          # f.input :buffet_price, label: "Per User Buffet Price", input_html: { value: (f.object.buffet_price == 0.0 ? (f.object.menu_dinner.present? && f.object.menu_dinner.fooditems.present?) ? f.object.menu_dinner.fooditems.order("price DESC").first.price : ((f.object.menu_lunch.present? && f.object.menu_lunch.fooditems.present?) ? f.object.menu_lunch.fooditems.order("price DESC").first.price : 0.0) : f.object.buffet_price)}
          f.input :alert_email,label: "Hide Restaurant From Dashboard", as: :boolean
          # f.has_many :restaurant_admin, heading: nil, allow_destroy: true, class: 'has_one' do |r|
          #   r.input :first_name
          #   r.input :last_name
          #   r.input :email
          #   a.input :status, as: :boolean, label: "Delete", :checked_value => "deleted", :unchecked_value => "active" unless r.object.new_record?
          # end
          f.has_many :contacts, heading: nil, allow_destroy: true do |c|
            c.input :name
            c.input :phone_number
            c.input :send_text_reminders, as: :boolean
            c.input :email
            c.input :email_summary_check, label: "Automatically Send Order Summary", as: :boolean
            c.input :email_label_check, label: "Automatically Send Labels", as: :boolean
            c.input :fax
            c.input :fax_summary_check, label: "Automatically Fax Order Summary", as: :boolean
          end
          f.has_many :holidays, heading: nil, allow_destroy: true do |c|
            c.input :start_date
            c.input :end_date
          end
          rand_ = rand_ + 1;
          f.input :lunch_order_capacity, label: "Lunch Capacity"
          f.input :dinner_order_capacity, label: "Dinner Capacity"
          # columns do
          #     column do
          #       f.input :monday_first_start_time, label: 'Monday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.monday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :monday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.monday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :monday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.monday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :monday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.monday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :tuesday_first_start_time, label: 'Tuesday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.tuesday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :tuesday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.tuesday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #      column do
          #       f.input :tuesday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.tuesday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :tuesday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.tuesday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :wednesday_first_start_time, label: 'Wednesday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.wednesday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :wednesday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.wednesday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :wednesday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.wednesday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :wednesday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.wednesday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :thursday_first_start_time, label: 'Thursday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.thursday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #         f.input :thursday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.thursday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :thursday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.thursday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #         f.input :thursday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.thursday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :friday_first_start_time, label: 'Friday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.friday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :friday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.friday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :friday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.friday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :friday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.friday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :saturday_first_start_time, label: 'Saturday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.saturday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :saturday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.saturday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :saturday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.saturday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :saturday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.saturday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          # columns do
          #     column do
          #       f.input :sunday_first_start_time, label: 'Sunday', as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.sunday_first_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :sunday_first_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.sunday_first_end_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :sunday_second_start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.sunday_second_start_time.try(:strftime, '%H:%M') }
          #     end
          #     column do
          #       f.input :sunday_second_end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: f.object.sunday_second_end_time.try(:strftime, '%H:%M') }
          #     end
          # end
          f.input :notes, input_html: {rows: 3}
        end
        f.inputs class: "driverShifts" do
          time_zone = f.object.addressable.time_zone
          if f.object.errors.blank?
            default_time = '00:00'.in_time_zone(f.object.addressable.time_zone)
            f.object.monday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.monday_shifts.blank?
            f.object.tuesday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.tuesday_shifts.blank?
            f.object.wednesday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.wednesday_shifts.blank?
            f.object.thursday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.thursday_shifts.blank?
            f.object.friday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.friday_shifts.blank?
            f.object.saturday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.saturday_shifts.blank?
            f.object.sunday_shifts.build(start_time: default_time, end_time: default_time, closed: true) if f.object.sunday_shifts.blank?
          end
          f.has_many :monday_shifts, heading: "Mon", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Monday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :tuesday_shifts, heading: "Tue", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Tuesday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :wednesday_shifts, heading: "Wed", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Wednesday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :thursday_shifts, heading: "Thu", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Thursday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :friday_shifts, heading: "Fri", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Friday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :saturday_shifts, heading: "Sat", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Saturday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
          f.has_many :sunday_shifts, heading: "Sun", new_record: '+', allow_destroy: true do |s|
            s.input :label, as: :hidden, value: "Sunday"
            s.input :time_zone, as: :hidden, input_html: { value: time_zone }
            s.input :start_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.start_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :end_time, label: false, as: :date_time_picker, picker_options: { datepicker: false, format: "H:i", step: 10, value: s.object.end_time&.in_time_zone(f.object.addressable.time_zone).try(:strftime, '%H:%M') }
            s.input :closed, input_html: { class: 'has_many_close'}
          end
        end
      end
      tab "Marketplace Settings", html_options: { class: (f.object.errors.present? && (f.object.errors.include?(:images) || f.object.errors.include?(:delivery_radius) || f.object.errors.include?(:delivery_cost) || f.object.errors.include?(:individual_meals_cutoff) || f.object.errors.include?(:buffet_cutoff) || f.object.errors.include?(:minimum_order_quantity)) ) ? 'ui-tabs-active ui-state-active' : '' } do
        f.inputs do
          f.semantic_errors :images
          f.input :enable_marketplace
          f.input :enable_self_service
          f.input :delivery_radius
          f.input :delivery_cost
          f.input :individual_meals_cutoff, input_html: { min: 0, step: 1}
          f.input :buffet_cutoff, input_html: { min: 0, step: 1}
          f.input :minimum_order_quantity
          f.input :random_menu_images
          # f.input :image, label: false , as: :file, hint: image_tag(f.object.image.thumb)
          f.input :logo, as: :file, hint: f.object.logo.blank? ? "" : image_tag(f.object.logo_url(:thumb))
          f.has_many :images, allow_destroy: true do |image|
            if image.object.new_record?
              image.input :image, as: :file, hint: image.object.image.blank? ? "" : image.template.image_tag(image.object.image_url(:thumb))
            else
              image.input :image, label: false, as: :file, hint: image.template.image_tag(image.object.image_url(:thumb))
            end
          end
        end
      end
    end

    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row ("Name") {|a| a.address_name}
      row ("Address") {|a| a.address_line}
      row ("Payout (days)") {|a| a.delayed_payout_days}
      row ("Commission ( % )") {|a| a.discount_percentage}
      # row ("Per User Buffet Price") {|a| a.buffet_price}
      row 'Contacts' do
        render partial: 'admin/contacts/contact', locals: {contacts: resource.contacts}
      end
      row 'Details' do
        render partial: 'admin/addresses/address', locals: {address: resource}
      end
      panel "Restaurant Holidays" do
        table_for resource.holidays do
          column :start_date
          column :end_date
        end
      end
      panel "Restaurant Shifts" do
        panel "Monday" do
          table_for resource.monday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Tuesday" do
          table_for resource.tuesday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Wednesday" do
          table_for resource.wednesday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Thursday" do
          table_for resource.thursday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Friday" do
          table_for resource.friday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Saturday" do
          table_for resource.saturday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
        panel "Sunday" do
          table_for resource.sunday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(s.address.addressable.time_zone).strftime("%H:%M")}
            column :closed
          end
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/address_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Address").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  member_action :delete, method: :get do
    address = RestaurantAddress.find(params[:id])
    if Runningmenu.joins(:addresses).where("runningmenus.delivery_at > ? AND runningmenus.status != ? AND addresses.id = ?", Time.current, Runningmenu.statuses[:cancelled], address.id).blank?
      if address.addressable.deleted? && address.addressable_type == 'Restaurant'
        redirect_to admin_restaurant_addresses_path(address.addressable_id), notice: "Restaurant is deleted, action can't be performed."
      elsif address.parent_status_active? || address.active?
        address.parent_status_deleted!
        redirect_to admin_restaurant_addresses_path(address.addressable_id), notice: "Address has been successfully deleted"
      end
    else
      redirect_to admin_restaurant_addresses_path(restaurant_id: address.addressable_id), alert: "Restaurant Location #{address.address_line} cannot be delete as it have some active meetings"
    end
  end

  member_action :active, method: :get do
    address = RestaurantAddress.find(params[:id])
    if address.addressable.deleted? && address.addressable_type == 'Restaurant'
      redirect_to admin_restaurant_addresses_path(address.addressable_id), notice: "Restaurant is deleted, action can't be performed."
    elsif address.parent_status_deleted? || address.deleted?
      address.parent_status_active!
      redirect_to admin_restaurant_addresses_path(address.addressable_id), notice: "Address haas been successfully active"
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
    belongs_to :restaurant, polymorphic: true
  end

  collection_action :restaurant_addresses, method: :get do
    restaurant_addresses = RestaurantAddress.active.where("(address_line ILIKE :prefix)", prefix: "%#{params[:q][:groupings]["0"]["name_contains"]}%")
    render json: restaurant_addresses.collect {|cl| {:id => cl.id, :name => cl.name} }
  end

  member_action :company_budget do
    c_address = CompanyAddress.find params[:id]
    render json: { budget: c_address.addressable.user_meal_budget, user_copay: c_address.addressable.user_copay, copay_amount: c_address.addressable.copay_amount }
  end

  member_action :company_fields do
    addr = CompanyAddress.find(params[:id])
    if params["runningmenu_id"].present?
      runningmenu = Runningmenu.find(params[:runningmenu_id])
    end
    data = ''
    counter = 0
    addr.addressable.fields.active.order(position: :asc).each do |field|
      if runningmenu.present? && runningmenu.runningmenufields.present?
        runningmenu_field = runningmenu.runningmenufields.find_by_field_id(field.id)
        field = runningmenu_field.field if runningmenu_field.present?
        data = data + "<li class='hidden input optional' id='runningmenu_runningmenufields_attributes_#{counter}_id_input'><input id='runningmenu_runningmenufields_attributes_#{counter}_id' type='hidden' value='#{runningmenu_field.id}' name='runningmenu[runningmenufields_attributes][#{counter}][id]'></li>" if runningmenu_field.present?
      end
      if field.dropdown?
        data = data + "<li class='hidden input optional' id='runningmenu_runningmenufields_attributes_#{counter}_field_id_input'><input id='runningmenu_runningmenufields_attributes_#{counter}_field_id' type='hidden' value='#{field.id}' name='runningmenu[runningmenufields_attributes][#{counter}][field_id]'></li></li><li class='select input required' id='runningmenu_runningmenufields_attributes_#{counter}_fieldoption_id_input'><label for='runningmenu_runningmenufields_attributes_#{counter}_fieldoption_id' class='label'>#{field.name}</label><select name='runningmenu[runningmenufields_attributes][#{counter}][fieldoption_id]' #{ "required" if field.required?} id='runningmenu_runningmenufields_attributes_#{counter}_fieldoption_id'><option value=''></option>"
        field.fieldoptions.active.order(position: :asc).each do |fieldoption|
          runningmenu_fieldoption = runningmenu.runningmenufields.find_by_fieldoption_id(fieldoption.id) if runningmenu.present?
          selected_fieldoption = runningmenu_fieldoption.fieldoption if runningmenu_fieldoption.present?
          if selected_fieldoption.present?
            data = data + "<option selected='selected' value='#{selected_fieldoption.id}'>#{selected_fieldoption.name}</option>"
          else
            data = data + "<option value='#{fieldoption.id}'>#{fieldoption.name}</option>"
          end
        end
        data = data + "</select>"
      else
        data = data + "<li class='hidden input optional' id='runningmenu_runningmenufields_attributes_#{counter}_field_id_input'><input id='runningmenu_runningmenufields_attributes_#{counter}_field_id' type='hidden' value='#{field.id}' name='runningmenu[runningmenufields_attributes][#{counter}][field_id]'></li><li class='string input required stringish' id='runningmenu_runningmenufields_attributes_#{counter}_value_input'><label for='runningmenu_runningmenufields_attributes_#{counter}_value' class='label'>#{field.name}</label><input maxlength='4294967296' id='runningmenu_runningmenufields_attributes_#{counter}_value' type='text' value='#{runningmenu_field.value if runningmenu_field.present?}' name='runningmenu[runningmenufields_attributes][#{counter}][value]'></li>"
      end
      counter = counter + 1
    end
    render json: {data: data }
  end

  member_action :runningmenu_tags do
    company_id = CompanyAddress.find(params[:id]).addressable_id
    render json: ActsAsTaggableOn::Tag.for_tenant(company_id).order(id: :asc).pluck(:name)&.uniq
  end

  member_action :recurring_company_fields do
    addr = CompanyAddress.find(params[:id])
    if params["recurring_scheduler_id"].present?
      recurring_scheduler = RecurringScheduler.find(params[:recurring_scheduler_id])
    end
    data = ''
    counter = 0
    addr.addressable.fields.active.order(position: :asc).each do |field|
      if recurring_scheduler.present? && recurring_scheduler.runningmenufields.present?
        runningmenu_field = recurring_scheduler.runningmenufields.find_by_field_id(field.id)
        field = runningmenu_field.field if runningmenu_field.present?
        data = data + "<li class='hidden input optional' id='recurring_scheduler_runningmenufields_attributes_#{counter}_id_input'><input id='recurring_scheduler_runningmenufields_attributes_#{counter}_id' type='hidden' value='#{runningmenu_field.id}' name='recurring_scheduler[runningmenufields_attributes][#{counter}][id]'></li>" if runningmenu_field.present?
      end
      if field.dropdown?
        data = data + "<li class='hidden input optional' id='recurring_scheduler_runningmenufields_attributes_#{counter}_field_id_input'><input id='recurring_scheduler_runningmenufields_attributes_#{counter}_field_id' type='hidden' value='#{field.id}' name='recurring_scheduler[runningmenufields_attributes][#{counter}][field_id]'></li></li><li class='select input required' id='recurring_scheduler_runningmenufields_attributes_#{counter}_fieldoption_id_input'><label for='recurring_scheduler_runningmenufields_attributes_#{counter}_fieldoption_id' class='label'>#{field.name}</label><select name='recurring_scheduler[runningmenufields_attributes][#{counter}][fieldoption_id]' #{ "required" if field.required?} id='recurring_scheduler_runningmenufields_attributes_#{counter}_fieldoption_id'><option value=''></option>"
        field.fieldoptions.active.order(position: :asc).each do |fieldoption|
          recurring_scheduler_fieldoption = recurring_scheduler.runningmenufields.find_by_fieldoption_id(fieldoption.id) if recurring_scheduler.present?
          selected_fieldoption = recurring_scheduler_fieldoption.fieldoption if recurring_scheduler_fieldoption.present?
          if selected_fieldoption.present?
            data = data + "<option selected='selected' value='#{selected_fieldoption.id}'>#{selected_fieldoption.name}</option>"
          else
            data = data + "<option value='#{fieldoption.id}'>#{fieldoption.name}</option>"
          end
        end
        data = data + "</select>"
      else
        data = data + "<li class='hidden input optional' id='recurring_scheduler_runningmenufields_attributes_#{counter}_field_id_input'><input id='recurring_scheduler_runningmenufields_attributes_#{counter}_field_id' type='hidden' value='#{field.id}' name='recurring_scheduler[runningmenufields_attributes][#{counter}][field_id]'></li><li class='string input required stringish' id='recurring_scheduler_runningmenufields_attributes_#{counter}_value_input'><label for='recurring_scheduler_runningmenufields_attributes_#{counter}_value' class='label'>#{field.name}</label><input maxlength='4294967296' id='recurring_scheduler_runningmenufields_attributes_#{counter}_value' type='text' value='#{runningmenu_field.value if runningmenu_field.present?}' name='recurring_scheduler[runningmenufields_attributes][#{counter}][value]'></li>"
      end
      counter = counter + 1
    end
    render json: {data: data }
  end

  # member_action :map do
  #   restaurant_ids = Distance.all(:d).where("d.company_address_id={ca_id} and d.distance > {min}").params({ca_id: params[:id].to_i,min: 0.0}).pluck(:restaurant_address_id)
  #   markers = RestaurantAddress.active.where(:id=>restaurant_ids).collect do |r|
  #     {
  #       "lat"=> r.latitude,
  #       "lng"=> r.longitude,
  #       "picture"=> {
  #         "width"=> 50,
  #         "height"=> 50,
  #         "url"=>ActionController::Base.helpers.asset_url('r_marker.png')
  #       },
  #       "infowindow"=> r.name
  #     }
  #   end
  #   c_address = CompanyAddress.find params[:id]
  #   markers << {
  #     "lat"=> c_address.latitude,
  #     "lng"=> c_address.longitude,
  #     "picture"=> {
  #       "url"=> "http://i.imgur.com/Na6VUFY.png",
  #       "width"=> 50,
  #       "height"=> 50
  #     },
  #     "infowindow"=> c_address.name
  #   }
  #   render json: markers
  # end

  collection_action :map_markers, method: :get do
    where_str = "addresses.latitude IS NOT NULL AND addresses.longitude IS NOT NULL"
    joins_str = "INNER JOIN addresses ON addresses.addressable_id = restaurants.id AND addresses.addressable_type = 'Restaurant'"
    unless params[:name].blank?
      where_str += " AND restaurants.name ILIKE '%#{params[:name]}%'"
    end
    unless params[:zip].blank?
      where_str += " AND addresses.zip = '#{params[:zip]}'"
    end
    unless params[:status].blank?
      where_str += " AND addresses.status = #{params[:status]}"
    end
    unless params[:menu_type].blank?
      joins_str += " INNER JOIN menus ON menus.address_id = addresses.id AND menus.menu_type = #{Menu.menu_types[params[:menu_type].downcase.to_sym]} AND menus.status = 0"
    end
    unless params[:cuisines_ids].blank?
      where_str += " AND cuisines_restaurants.cuisine_id IN(#{params[:cuisines_ids]})"
      joins_str += " INNER JOIN cuisines_restaurants ON cuisines_restaurants.restaurant_id = restaurants.id"
    end
    restaurants = Restaurant.joins(joins_str).select("addresses.id, addresses.addressable_id, restaurants.name, addresses.latitude, addresses.longitude, addresses.address_line, addresses.discount_percentage").where(where_str)
    markers = []
    infowindows = []
    restaurants.each do |r|
      marker_color = r.discount_percentage > 0.0 ? 'http://maps.google.com/mapfiles/kml/paddle/grn-circle.png' : ''
      link = ENV["BACKEND_HOST"]+"/admin/restaurants/#{r.addressable_id}/addresses/#{r.id}"
      anchor_link = "<a href='#{link}'>#{r.name+": "+r.address_line}</a>"
      markers << [r.name+": "+r.address_line, r.latitude, r.longitude, marker_color, anchor_link]
      infowindows << [r.name+": "+r.address_line]
    end
    render json: {markers: markers, infowindows: infowindows}
  end

  member_action :billing_information, method: :patch do
    @address = Address.find(params[:id])
    count = 0
    if params[:address][:dishsizes_attributes].present?
      params[:address][:dishsizes_attributes].each do |number , a|
        if a[:parent_status] == "active" || a[:parent_status].blank?
          count += 1
          break
        end
      end
      if count == 1 && @address.update(permitted_params[:address])
        if @address.menu_buffet.present? && (@address.menu_buffet.fooditems.count != @address.menu_buffet.fooditems.joins(:dishsizes).uniq.count)
          flash[:error] = "Please attach dishsizes to fooditems."
          redirect_to edit_admin_restaurant_address_menu_path(address_id: @address.id, id: @address.menu_buffet.id, restaurant_id: @address.addressable.id)
        elsif @address.menu_buffet.present?
          redirect_to edit_admin_restaurant_address_menu_path(address_id: @address.id, id: @address.menu_buffet.id, restaurant_id: @address.addressable.id), notice: "Billing Saved successfully."
        else
          redirect_to new_admin_restaurant_address_menu_path(address_id: @address.id, type: 'buffet', restaurant_id: @address.addressable.id), notice: "Billing Saved successfully."
        end
      else
        if !@address.errors.present?
          flash[:error] = "Please add atleast one dishsize"
        end
        render 'admin/menu/billing'
      end
    else
      flash[:error] = "Please add atleast one dishsize"
      render 'admin/menu/billing'
    end
  end

  filter :street_or_city_or_state_or_zip , as: :string, label: "Name"
  # filter :breakfast_order_capacity, label: "Breakfast Order Capacity"
  filter :lunch_order_capacity, label: "Lunch Order Capacity"
  filter :dinner_order_capacity, label: "Dinner Order Capacity"
end
