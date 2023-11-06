ActiveAdmin.register Driver do
  menu priority: 9
  config.batch_actions = false
  actions :all, except: :destroy

  permit_params do
    permitted = [
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :car,
      :car_color,
      :car_licence_plate,
      :image,
      :restaurant_address_id,
      monday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      tuesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      wednesday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      thursday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      friday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      saturday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ],
      sunday_shifts_attributes: [
        :id,
        :label,
        :start_time,
        :end_time,
        :time_zone,
        :_destroy
      ]
    ]
  end

  index do
    column :id
    column :first_name
    column :last_name
    column :email
    column "Phone Number" do |driver|
      link_to "#{driver.phone_number} <em class='fa fa-comment'></em>".html_safe, "javascript://", id: "open_chat", 'data-row-id':"#{driver.id}", 'data-row-name':"#{driver.name}"
    end
    column "Status" do |d|
      if d.active?
        status_tag( :active )
      elsif d.deleted?
        status_tag( :deleted )
      end
    end
    actions do |driver|
      if driver.active?
        item('Delete', delete_admin_driver_path(driver.id), class: [:member_link, :delete_btn])
      else
        item('Activate', active_admin_driver_path(driver.id) , class: [:member_link, :active_btn])
      end
    end
  end

  csv do
    column :id
    column :first_name
    column :last_name
    column :email
    column :phone_number
  end

  form do |f|
    div do
      link_to('Add a Book', restaurant_shifts_admin_drivers_path(id: f.object&.id), id: "trigger_restaurant_shifts", remote: true)
    end
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :phone_number, input_html: { class: f.object.new_record? ? '' : 'driver_phone_field'  }
      f.input :restaurant_address_id, label: 'Restaurant Address', as: :select, collection: RestaurantAddress.active.where(enable_self_service: true).map{ |ra| [ra.name, ra.id] }, include_blank: true, hint: "Blank address will associate driver to chowmill."
      f.input :car
      f.input :car_color, as: :string
      f.input :car_licence_plate
      f.input :image, as: :file, hint: image_tag(f.object.image.thumb)
    end
    f.inputs class: "driverShifts" do
      render 'driver_shifts', f: f
    end
    f.actions do
      f.action(:submit)
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row :email
      row :restaurant_address
      row :phone_number
      row "Status" do |d|
        if d.active?
          status_tag( :active )
        elsif d.deleted?
          status_tag( :deleted )
        end
      end
      panel "Driver Shifts" do
        time_zone = driver.restaurant_address.present? ? driver.restaurant_address.addressable.time_zone : 'US/Pacific'
        panel "Monday" do
          table_for driver.monday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Tuesday" do
          table_for driver.tuesday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Wednesday" do
          table_for driver.wednesday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Thursday" do
          table_for driver.thursday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Friday" do
          table_for driver.friday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Saturday" do
          table_for driver.saturday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
        panel "Sunday" do
          table_for driver.sunday_shifts do
            column :start_time {|s| s.start_time&.in_time_zone(time_zone).strftime("%H:%M")}
            column :end_time {|s| s.end_time&.in_time_zone(time_zone).strftime("%H:%M")}
          end
        end
      end
      panel "Audit log" do
        render partial: '/active_admin/versions/driver_model', locals: {versions: (resource.versions.includes(:item)+PaperTrail::Version.joins(:version_associations).where("version_associations.foreign_key_id = ? AND version_associations.foreign_type = ?",resource.id,"Driver").includes(:item)).sort_by(&:created_at).reverse}
      end
    end
  end

  member_action :delete, method: :get do
    driver = Driver.find(params[:id])
    if driver.worker_id.present?
      worker = Onfleet::Worker.get(driver.worker_id) rescue nil
    else
      worker = nil
    end
    if driver.active?
      if worker.present? && worker.tasks.present?
        flash[:notice] = "Driver can't be deleted due to assigned tasks."
        redirect_to admin_drivers_path
      else
        driver.deleted!
        redirect_to admin_drivers_path, notice: "Driver has been successfully deleted"
      end
    end
  end

  member_action :active, method: :get do
    driver = Driver.find(params[:id])
    if driver.deleted?
      driver.active!
      redirect_to admin_drivers_path, notice: "Driver haas been successfully active"
    end
  end
  collection_action :restaurant_shifts do
    @driver = params[:id].present? ? Driver.find(params[:id]) : Driver.new
    @restaurant_address = RestaurantAddress.find_by_id(params[:restaurant_address_id])
    @monday_shifts, @tuesday_shifts, @wednesday_shifts, @thursday_shifts, @friday_shifts, @saturday_shifts, @sunday_shifts = [], [], [], [], [], [], []
    if @restaurant_address.present? && @restaurant_address.id != @driver.restaurant_address_id
      @restaurant_address.monday_shifts.each do |shift|
        @monday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
      @restaurant_address.tuesday_shifts.each do |shift|
        @tuesday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
      @restaurant_address.wednesday_shifts.each do |shift|
        @wednesday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
      @restaurant_address.thursday_shifts.each do |shift|
        @thursday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end  # filter :restaurant_address, as: :select, collection: proc{ RestaurantAddress.active }

      @restaurant_address.friday_shifts.each do |shift|
        @friday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
      @restaurant_address.saturday_shifts.each do |shift|
        @saturday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
      @restaurant_address.sunday_shifts.each do |shift|
        @sunday_shifts << DriverShift.new(driver_id: @driver.id, label: shift.label, start_time: shift.start_time, end_time: shift.end_time)
      end
    end
  end

  controller do
    before_action :set_paper_trail_whodunnit
    skip_around_action :set_admin_timezone#, only: [:update]
  end

  filter :first_name
  filter :last_name
  filter :email
  filter :phone_number
  # filter :restaurant_address_id, label: 'Restaurant Location', as: :select, collection: proc{ RestaurantAddress.active.map{ |ra| [ra.name, ra.id] } }
  filter :restaurant_address_id, as: :search_select_filter, url: proc { restaurant_addresses_admin_addresses_path }, fields: [:name], display_name: 'name', minimum_input_length: 3, order_by: 'name_asc', width: '233px'
end
