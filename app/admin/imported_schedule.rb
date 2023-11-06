ActiveAdmin.register_page "Imported Schedules" do
  menu false
  content do
    successful_schedules = []
    failed_schedules = []
    TempSchedule.all.where(status: true, user_id: current_admin_user.id).each do |t|
      company_address = CompanyAddress.find_by_id(t.address_id)
      company_admin_id = company_address.default_admin.nil? ? company_address.addressable.company_admins.active.last.id : company_address.default_admin.id rescue nil
      dates = t.set_dates
      # runningmenu = Runningmenu.new(runningmenu_name: t.runningmenu_name, runningmenu_type: t.runningmenu_type, address_id: company_address&.id, delivery_at: t.delivery_at, submitted_from_bulk_upload: true, orders_count: t.orders_count, per_meal_budget: t.per_meal_budget,  user_id: current_admin_user.id, status: :pending, driver_id: Driver.find_by_id(t.driver_id)&.id, menu_type: t.menu_type, end_time: t.delivery_at&.strftime("%H:%M"), csv_imported: true, notify_admin: t.notify_admin)
      runningmenu = Runningmenu.new(runningmenu_name: t.runningmenu_name, runningmenu_type: t.runningmenu_type, address_id: company_address&.id, user_id: company_admin_id, delivery_at: dates[0], activation_at: dates[1], cutoff_at: dates[2], admin_cutoff_at: dates[3], submitted_from_bulk_upload: true, orders_count: t.orders_count, per_meal_budget: t.per_meal_budget, status: :pending, driver_id: Driver.find_by_id(t.driver_id)&.id, menu_type: t.menu_type, end_time: t.delivery_at&.strftime("%H:%M"), csv_imported: true, notify_admin: t.notify_admin)
      if t.cuisines.present?
        runningmenu.cuisines << Cuisine.where(name: t.cuisines.split(', '))
      end
      if t.address_ids.present?
        runningmenu.addresses << RestaurantAddress.where(id: t.address_ids.split(', '))
      end
      # if suggested_restaurant.present?
      #   runningmenu.addresses << RestaurantAddress.find_by_id(suggested_restaurant)
      #   runningmenu.suggested_restaurant = suggested_restaurant
      # end
      if runningmenu.save
        successful_schedules.push(runningmenu.id)
      else
        failed_schedules.push(t.id)
      end
    end
    render partial: 'admin/schedules/imported_schedules', locals: {failed_schedules: failed_schedules, runningmenus: Runningmenu.where(id: successful_schedules)}
    TempSchedule.where(user_id: current_admin_user.id)&.destroy_all
  end

  page_action :update_imported_schedules, method: :post do
    runningmenu = Runningmenu.find_by_id(params[:runningmenu_id])
    if runningmenu.nil?
      company_address = CompanyAddress.find_by_id(params[:address_id])
      company_admin_id = company_address.default_admin.nil? ? company_address.addressable.company_admins.active.last.id : company_address.default_admin.id rescue nil
      if params[:buffet].present? && params[:buffet] == "on"
        runningmenu = Runningmenu.new(address_id:
          params[:address_id], user_id: company_admin_id, runningmenu_name: params[:runningmenu_name], runningmenu_type: params[:runningmenu_type].to_i, delivery_at: params[:delivery_at], cutoff_at: params[:cutoff_at], admin_cutoff_at: params[:admin_cutoff_at], activation_at: Time.now, orders_count: params[:orders_count], per_meal_budget: params[:per_meal_budget], driver_id: params[:driver_id], notify_admin: params[:notify_admin].present? && params[:notify_admin] == "on" ? true : false,  menu_type: Runningmenu.menu_types[:buffet], address_ids: params[:address_ids].split(', '), csv_imported: true)
      else
        runningmenu = Runningmenu.new(address_id:
          params[:address_id], user_id: company_admin_id, runningmenu_name: params[:runningmenu_name], runningmenu_type: params[:runningmenu_type].to_i, delivery_at: params[:delivery_at], cutoff_at: params[:cutoff_at], admin_cutoff_at: params[:admin_cutoff_at], activation_at: Time.now, orders_count: params[:orders_count], per_meal_budget: params[:per_meal_budget], driver_id: params[:driver_id], notify_admin: params[:notify_admin].present? && params[:notify_admin] == "on" ? true : false,  menu_type: Runningmenu.menu_types[:individual], address_ids: params[:address_ids].split(', '), csv_imported: true)
      end
      if params[:cuisines].present?
        runningmenu.cuisines << Cuisine.where(name: params[:cuisines].split(', '))
      end
      if !runningmenu.save
        render json: { status: "failure", validation_errors: runningmenu.errors.full_messages&.join(",")&.gsub(",", ", ")}
      else
        render json: { status: "success", delivery_at: runningmenu.delivery_at_timezone.strftime('%a. %b %d %l:%M%P'), cutoff_at: runningmenu.cutoff_at_timezone.strftime('%a. %b %d %l:%M%P'), admin_cutoff_at: runningmenu.admin_cutoff_at_timezone.strftime('%a. %b %d %l:%M%P'), runningmenu_type: runningmenu.runningmenu_type, orders_count: runningmenu.orders_count, per_meal_budget: runningmenu.per_meal_budget, driver: runningmenu.driver.present? ? runningmenu.driver.name : "", notify_admin: runningmenu.notify_admin ? 'Yes' : 'No', menu_type: runningmenu.menu_type, addresses: (runningmenu.addresses.present? ? runningmenu.addresses.map{|a| a.name}.join(', <br>') : "").html_safe, runningmenu_name: runningmenu.runningmenu_name, runningmenu_id: runningmenu.id, company_location: runningmenu.address.name, address_ids: runningmenu.address_ids }
      end
    else
      if runningmenu.update(address_id: params[:address_id], user_id: company_admin_id, runningmenu_name: params[:runningmenu_name], runningmenu_type: params[:runningmenu_type].to_i, delivery_at: params[:delivery_at], cutoff_at: params[:cutoff_at], admin_cutoff_at: params[:admin_cutoff_at], orders_count: params[:orders_count], per_meal_budget: params[:per_meal_budget], driver_id: params[:driver_id], notify_admin: params[:notify_admin].present? && params[:notify_admin] == "on" ? true : false,  menu_type: params[:buffet].present? && params[:buffet] == "on" ? Runningmenu.menu_types[:buffet] : Runningmenu.menu_types[:individual], address_ids: params[:address_ids].split(', '))
        render json: { status: "success", delivery_at: runningmenu.delivery_at_timezone.strftime('%a. %b %d %l:%M%P'), cutoff_at: runningmenu.cutoff_at_timezone.strftime('%a. %b %d %l:%M%P'), admin_cutoff_at: runningmenu.admin_cutoff_at_timezone.strftime('%a. %b %d %l:%M%P'), runningmenu_type: runningmenu.runningmenu_type, orders_count: runningmenu.orders_count, per_meal_budget: runningmenu.per_meal_budget, driver: runningmenu.driver.present? ? runningmenu.driver.name : "", notify_admin: runningmenu.notify_admin ? 'Yes' : 'No', menu_type: runningmenu.menu_type, addresses: (runningmenu.addresses.present? ? runningmenu.addresses.map{|a| a.name}.join(', <br>') : "").html_safe, runningmenu_name: runningmenu.runningmenu_name, runningmenu_id: runningmenu.id, company_location: runningmenu.address.name, address_ids: runningmenu.address_ids  }
     else
       render json: { status: "failure", validation_errors: runningmenu.errors.full_messages&.join(",")&.gsub(",", ", ")}
     end
    end
  end

  controller do
    skip_before_action :verify_authenticity_token, only: [:upload_csv, :update_imported_schedules]
    skip_around_action :set_admin_timezone
  end
end
