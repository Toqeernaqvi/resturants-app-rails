ActiveAdmin.register_page "Selected Schedules" do
  menu false
  content do
    render partial: 'admin/schedules/selected_schedules'
  end

  page_action :upload_csv, method: :post do
    TempSchedule.where(user_id: current_admin_user.id)&.destroy_all
    CSV.parse(params[:bulkScheduleCsv].read, :headers => true) do |row|
      if row.headers.include?('Driver')
        str   = row['Delivery Date']
        if str =~ /\d{2}\/\d{2}\/\d{2}/ || str =~ /\d{1}\/\d{2}\/\d{2}/ || str =~ /\d{1}\/\d{1}\/\d{2}/
          begin
            date =  Date.strptime(row['Delivery Date'], "%m/%d/%y")
            row['Delivery Date'] = date.strftime('%Y-%m-%d')
          rescue ArgumentError => e
            redirect_to admin_schedulers_path, notice: "Please upload correct format file"
            return
          end
        elsif str =~ /\d{4}-\d{2}-\d{2}/
          begin
            date =  Date.strptime(row['Delivery Date'], "%Y-%m-%d")
            row['Delivery Date'] = date.strftime('%Y-%m-%d')
          rescue ArgumentError => e
            redirect_to admin_schedulers_path, notice: "Please upload correct format file"
            return
          end
        elsif row['Pickup Date'] =~ /\d{2}\/\d{2}\/\d{2}/ || row['Pickup Date'] =~ /\d{1}\/\d{2}\/\d{2}/ || row['Pickup Date'] =~ /\d{1}\/\d{1}\/\d{2}/
          begin
            date =  Date.strptime(row['Pickup Date'], "%m/%d/%y")
            row['Pickup Date'] = date.strftime('%Y-%m-%d')
          rescue ArgumentError => e
            redirect_to admin_schedulers_path, notice: "Please upload correct format file"
            return
          end
        elsif row['Pickup Date'] =~ /\d{4}-\d{2}-\d{2}/
          begin
            date =  Date.strptime(row['Pickup Date'], "%Y-%m-%d")
            row['Pickup Date'] = date.strftime('%Y-%m-%d')
          rescue ArgumentError => e
            redirect_to admin_schedulers_path, notice: "Please upload correct format file"
            return
          end
        else
          redirect_to admin_schedulers_path, notice: "Please upload correct format file"
          return
        end
        if row['Driver'].blank?
          driverID = nil
        elsif row['Delivery Date'].present? && row['Delivery Time'].present? && row['Pickup Date'].present? && row['Pickup Time'].present?
          driverID = Driver.available_on("#{row['Delivery Date'] + ' ' +row['Delivery Time']}", "#{row['Pickup Date'] + ' ' +row['Pickup Time']}", 'pickup', row['Company Location ID'], nil)&.pluck(:id).include?(row['Driver'].to_i)?  row['Driver'].to_i : ''
        else
          driverID = nil
        end
        runningmenu = Runningmenu.new(runningmenu_name: row['Meeting Name'], runningmenu_type: row['Meal'].blank? ? '' : Runningmenu.runningmenu_types[row['Meal']&.downcase], address_id: CompanyAddress.find_by_id(row['Company Location ID'])&.id, delivery_at: row['Delivery Date'] + ' ' +row['Delivery Time'], orders_count: row['Count'], per_meal_budget: row['Budget'],  user_id: current_admin_user.id, status: :pending, driver_id: driverID, menu_type: row['Menu Type'].blank? ? '' : Runningmenu.menu_types[row['Menu Type']&.downcase], end_time: row['Delivery Time'], submitted_from_bulk_upload_new: true, csv_imported: true, notify_admin: row['Notify Admin'] == 'Yes' ? true : false)
        runningmenu.calculate_time
        temp_schedule = TempSchedule.create(validation_errors: runningmenu.valid? ? "" : runningmenu.errors.full_messages&.join(",")&.gsub(",", ", "), user_id: current_admin_user.id, cuisines: row['Cuisine Preference'],runningmenu_name: row['Meeting Name'], runningmenu_type: Runningmenu.runningmenu_types[row['Meal']&.downcase], address_id: row['Company Location ID']&.to_i, delivery_at: "#{row['Delivery Date'].present? ? row['Delivery Date'] + ' ' +row['Delivery Time'] : ''}", cutoff_at: runningmenu.cutoff_at, admin_cutoff_at: runningmenu.admin_cutoff_at, orders_count: row['Count']&.to_i, per_meal_budget: row['Budget']&.to_i, driver_id: driverID, menu_type: Runningmenu.menu_types[row['Menu Type']&.downcase], notify_admin: row['Notify Admin'].present? && row['Notify Admin'] == 'Yes'? true : false, status: runningmenu.valid? ? true : false)
      else
        redirect_to admin_schedulers_path, notice: "Please upload correct format file"
        return
      end
    end
    redirect_to admin_selected_schedules_path()#, notice: "Schedulers have been successfully imported."
  end

  page_action :update_temp_schedules, method: :post do
    temp_schedule = TempSchedule.find_by_id(params[:temp_schedule_id])
    runningmenu = Runningmenu.new(user_id: current_admin_user.id, status: :pending, csv_imported: true, address_id: params[:address_id], runningmenu_name: params[:runningmenu_name], runningmenu_type: params[:runningmenu_type].to_i, delivery_at: params[:delivery_at], cutoff_at: params[:cutoff_at], admin_cutoff_at: params[:admin_cutoff_at], orders_count: params[:orders_count], per_meal_budget: params[:per_meal_budget], driver_id: params[:driver_id], notify_admin: params[:notify_admin].present? && params[:notify_admin] == "on" ? true : false,  menu_type: params[:buffet].present? && params[:buffet] == "on" ? Runningmenu.menu_types[:buffet] : Runningmenu.menu_types[:individual], address_ids: params[:address_ids])
    if temp_schedule.update(validation_errors: runningmenu.valid? ? "" : runningmenu.errors.full_messages&.join(",")&.gsub(",", ", "), address_id: params[:address_id], runningmenu_name: params[:runningmenu_name], runningmenu_type: params[:runningmenu_type].to_i, delivery_at: params[:delivery_at], cutoff_at: params[:cutoff_at], admin_cutoff_at: params[:admin_cutoff_at], orders_count: params[:orders_count], per_meal_budget: params[:per_meal_budget], driver_id: params[:driver_id], notify_admin: params[:notify_admin].present? && params[:notify_admin] == "on" ? true : false,  menu_type: params[:buffet].present? && params[:buffet] == "on" ? Runningmenu.menu_types[:buffet] : Runningmenu.menu_types[:individual], address_ids: params[:address_ids])
      render json: { status: "success", validation_errors: temp_schedule.validation_errors, delivery_at: temp_schedule.delivery_at&.strftime('%a. %b %d %l:%M%P'), cutoff_at: temp_schedule.cutoff_at&.strftime('%a. %b %d %l:%M%P'), admin_cutoff_at: temp_schedule.admin_cutoff_at&.strftime('%a. %b %d %l:%M%P'), runningmenu_type: Runningmenu.runningmenu_types.keys[temp_schedule.runningmenu_type], orders_count: temp_schedule.orders_count, per_meal_budget: temp_schedule.per_meal_budget, driver: temp_schedule.driver_id.present? ? Driver.find_by_id(temp_schedule.driver_id)&.name : "", notify_admin: temp_schedule.notify_admin ? 'Yes' : 'No', menu_type: Runningmenu.menu_types.keys[temp_schedule.menu_type], addresses: (temp_schedule.address_ids.present? ? temp_schedule.address_ids.split(', ').map{|a| RestaurantAddress.find_by_id(a).name}.join(', <br>') : "").html_safe, runningmenu_name: temp_schedule.runningmenu_name, runningmenu_id: temp_schedule.id, company_location: temp_schedule.address_id.present? ? CompanyAddress.find_by_id(temp_schedule.address_id)&.name : "", address_ids: temp_schedule.address_ids&.split(', ')  }
    else
      render json: { status: "failure", validation_errors: temp_schedule.validation_errors}
    end
  end

  page_action :change_status, method: :post do
    schedule = TempSchedule.find_by_id(params[:rowID])
    schedule.update_column(:status, params[:status] == 'on' ? true : false)
  end

  action_item :view_site do
    link_to "Next", admin_imported_schedules_path
  end

  controller do
    skip_before_action :verify_authenticity_token, only: [:upload_csv, :change_status, :update_temp_schedules]
    skip_around_action :set_admin_timezone
  end
end
