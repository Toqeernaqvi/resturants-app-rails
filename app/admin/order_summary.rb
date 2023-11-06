
ActiveAdmin.register_page "Order Report" do
  menu parent: 'Orders', priority: 2

  content do
    orders = []
    scheduler = Runningmenu.find_by_id params[:s]
    if !orders.present? && scheduler.present?
      orders = Order.order_summary(scheduler)
    end
    if scheduler.present?
      render partial: 'admin/orders/order_summary', locals: {orders: orders, grouping: scheduler.company.enable_grouping_orders}
    else
      render partial: 'admin/orders/order_summary', locals: {orders: orders}
    end
  end

  page_action :csv, method: :get do
    orders = []
    user = false
    scheduler = Runningmenu.find_by_id params[:s]
    orders = Order.order_summary(scheduler, false)
    csv = CSV.generate( encoding: 'Windows-1251' ) do |csv|
      csv << [ "User Name", "Restaurant Name", "Item Name", "Options", "Extra Instructions", "Quantity"]
      orders.each do |order|
        usernames = order.user_name.split(",")
        csv << [(usernames.count < 2 ? order.user_name : ""), order.restaurant_name, order.fooditem_name, order.options&.split(', ')&.map{|o| o.split('$')[0]}&.join(', '), order.remarks, order.quantity]
      end
    end

    send_data csv.encode('UTF-8'), type: 'text/csv; charset=utf-8; header=present', disposition: "attachment; filename=order_report.csv"
  end

  page_action :pdf, method: :get do
    FileUtils.mkdir_p 'public/summary'
    FileUtils.mkdir_p 'public/summaryzip'
    respond_to do |format|
      format.pdf do
        path = []
        orders = []
        counter = 0
        user = false
        scheduler = Runningmenu.find_by_id params[:s]
        delivery_at = scheduler.delivery_at_timezone
        restaurants = Order.getrestaurant(scheduler)
        if params[:restaurant_address_id].present?
          orders = Order.order_summary(scheduler, true, 0, 0, params[:restaurant_address_id].to_i)
        elsif restaurants.count < 2
          orders = Order.order_summary(scheduler, true)
        end
        if restaurants.count > 1 && !params[:restaurant_address_id].present?
          restaurants.each_with_index do |restaurant, index|
            orders = Order.order_summary(scheduler, true, restaurant.restaurant_id, restaurant.company_location_id)
            address = "#{restaurant.addresses_short_code + "-" if restaurant.addresses_short_code.present?}"+"#{restaurant.restaurant_name + '-' }"+"#{delivery_at.strftime('%a, %d %b %Y %H:%M:%S')}"
            ac = ActionController::Base.new()
            if path.include?(address + ".pdf")
              file_path = address + "(#{counter += 1}).pdf"
            else
              file_path = address + ".pdf"
            end
            path.push(file_path)
            template_path = params[:buffet].present? && params[:buffet] == "true" ? "admin/orders/buffetsummarypdf.html.erb" : "admin/orders/ordersummarypdf.html.erb"
            pdf = ac.render_to_string pdf: file_path, template: template_path, locals: { orders: orders, delivery_at: delivery_at, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p"), runningmenu: scheduler, address_id: restaurant.address_id}, encoding: "UTF-8"
            save_path = Rails.root.join('public','summary', file_path)
            File.open(save_path, 'wb') do |file|
              file << pdf
            end
          end
          folder = Rails.root.join('public','summary')
          zipfile_name = Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")

          Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
            path.each do |filename|
              zipfile.add(filename, File.join(folder, filename))
            end
          end
          file = File.open(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"), "rb")
          contents = file.read
          file.close
          File.delete(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")) if File.exist?(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"))
          path.each do |f_name|
            File.delete(Rails.root.join('public','summary',f_name)) if File.exist?(Rails.root.join('public','summary', f_name))
          end
          send_data(contents, :type => 'application/zip', :filename => "#{orders.first.short_code.to_s + "-" if orders.first.short_code.present? }"+" #{delivery_at.strftime('%a, %d %b %Y %H:%M:%S')}.zip")
        end
        if (restaurants.count < 2 || params[:restaurant_address_id].present?)          
          template_path = params[:buffet].present? && params[:buffet] == "true" ? "admin/orders/buffetsummarypdf.html.erb" : "admin/orders/ordersummarypdf.html.erb"
          render pdf: "#{orders.first.short_code + "-" if orders.first.short_code.present?}"+"#{orders.first.restaurant_name + '-' }"+"#{delivery_at.strftime('%a, %d %b %Y %H:%M:%S')}", template: template_path, locals: { orders: orders, delivery_at: delivery_at, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p"), runningmenu: scheduler, address_id: params[:restaurant_address_id].present? ? params[:restaurant_address_id] : restaurants.last.address_id}
        end
      end
    end
  end

  page_action :labelspdf, method: :get do
    FileUtils.mkdir_p 'public/summary'
    FileUtils.mkdir_p 'public/summaryzip'
    path = []
    orders = []
    counter = 0
    scheduler = Runningmenu.find_by_id params[:s]
    delivery_at = scheduler.delivery_at_timezone.strftime('%a %d %b %Y-%H:%M:%S')
    restaurants = Order.getrestaurant(scheduler)
    if params[:restaurant_address_id].present?
      orders = Order.order_summary(scheduler, false, 0, 0, params[:restaurant_address_id].to_i)
    elsif restaurants.count < 2
      orders = Order.order_summary(scheduler, false)
    end
    if restaurants.count > 1 && !params[:restaurant_address_id].present?
      restaurants.each_with_index do |restaurant, index|
        orders = Order.order_summary(scheduler, false, restaurant.restaurant_id, restaurant.company_location_id)
        csv = CSV.generate( encoding: 'UTF-8' ) do |csv|
          EmailLog.populate_csv(scheduler, orders, csv)
        end
        address = "#{restaurant.addresses_short_code + "-" if restaurant.addresses_short_code.present?}"+"#{restaurant.restaurant_name + '-' }"+"#{delivery_at}"
        if path.include?(address + ".csv")
          file_path = address + "(#{counter += 1}).csv"
        else
          file_path = address + ".csv"
        end
        save_path = Rails.root.join('public','summary', file_path)
        path.push(file_path)
        File.open(save_path, 'wb') do |file|
          file << csv
        end
      end
      folder = Rails.root.join('public','summary')
      zipfile_name = Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")

      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        path.each do |filename|
          zipfile.add(filename, File.join(folder, filename))
        end
      end
      file = File.open(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"), "rb")
      contents = file.read
      file.close
      File.delete(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")) if File.exist?(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"))
      path.each do |f_name|
        File.delete(Rails.root.join('public','summary',f_name)) if File.exist?(Rails.root.join('public','summary', f_name))
      end
      send_data(contents, :type => 'application/zip', :filename => "#{orders.first.short_code + "-" if orders.first.short_code.present? }"+"#{delivery_at}.zip")
    end
    if (restaurants.count < 2 || params[:restaurant_address_id].present?)      
      if params[:labels_word]
        generate_docx_file(orders, scheduler)
      else
        csv = CSV.generate( encoding: 'UTF-8' ) do |csv|
          EmailLog.populate_csv(scheduler, orders, csv)
        end
        send_data csv.encode('UTF-8'), type: 'text/csv; charset=utf-8; header=present', disposition: "attachment; filename=#{orders.first.short_code + "-" if orders.first.short_code.present? }"+"#{orders.first.restaurant_name + "-"}"+"#{delivery_at}.csv"
      end
    end
  end

  page_action :docx, method: :get do
    FileUtils.mkdir_p 'public/summary'
    FileUtils.mkdir_p 'public/summaryzip'
    respond_to do |format|
      format.docx do
        path = []
        orders = []
        scheduler = Runningmenu.find_by_id params[:s]
        delivery_at = scheduler.delivery_at_timezone
        restaurants = Order.getrestaurant(scheduler)
        orders = Order.order_summary(scheduler, false)
        if restaurants.count > 1
          restaurants.each_with_index do |restaurant, index|
            orders = Order.order_summary(scheduler, false, restaurant.restaurant_id, restaurant.company_location_id)
            ac = ActionController::Base.new()
            docx = ac.render_to_string partial: "admin/order_report/labelsword.html.erb", locals: { orders: orders, delivery_at: delivery_at, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p")}, encoding: "UTF-8"
            save_path = Rails.root.join('public','summary',"#{restaurant.restaurant_name}_#{restaurant.company_location}_#{delivery_at}.doc")
            path.push("#{restaurant.restaurant_name}_#{restaurant.company_location}_#{delivery_at}.doc")
            File.open(save_path, 'wb') do |file|
              file << docx
            end
          end
          folder = Rails.root.join('public','summary')
          zipfile_name = Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")

          Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
            path.each do |filename|
              zipfile.add(filename, File.join(folder, filename))
            end
          end
          file = File.open(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"), "rb")
          contents = file.read
          file.close
          File.delete(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip")) if File.exist?(Rails.root.join('public','summaryzip',"summary #{Date.today}.zip"))
          path.each do |f_name|
            File.delete(Rails.root.join('public','summary',f_name)) if File.exist?(Rails.root.join('public','summary', f_name))
          end
          send_data(contents, :type => 'application/zip', :filename => "Order Summary | #{delivery_at}.zip")
        end

        if restaurants.count < 2
          document = render_to_string partial: 'admin/order_report/labelsword.html.erb', locals: { orders: orders, delivery_at: delivery_at, pickup_time: scheduler.pickup_at_timezone.strftime("%I:%M %p")}
          send_data(document, :type => 'application/doc', :filename => "Order Summary | #{delivery_at}.doc")
        end
      end
    end
   end

  controller do
    include OrderHelper
    respond_to :docx

    def index
     if params['s'].present?
       @runningmenu = Runningmenu.find_by_id(params['s'])
       if !@runningmenu.present? || !@runningmenu.approved?
         flash.now[:notice] = "No such record Exists"
       elsif @runningmenu.present? && @runningmenu.approved? && !@runningmenu.orders.active.present?
         flash.now[:notice] = "Orders not exists for scheduler #{@runningmenu.id}"
       end
       render :index
     end
    end

    def generate_docx_file(orders, scheduler)
      csv = CSV.open(Rails.root.join('app/assets/csvs/file.csv'), "wb") do |csv|
        EmailLog.populate_csv(scheduler, orders, csv)
      end
      request = RestClient::Request.new(:method => :post, :url => "#{ENV['LABELS_PORTAL_URL']}/process.php", :payload => {:multipart => true, :file => File.new(Rails.root.join('app/assets/csvs/file.csv'), 'rb')})
      response = request.execute
      save_path = Rails.root.join('public','summary',"#{response.body.split("/")[1]}")
      File.open(save_path, 'wb') do |file|
        file << open("#{ENV['LABELS_PORTAL_URL']}/#{response.body}").read
      end
      File.open("#{Rails.root}/public/summary/#{response.body.split("/")[1]}", 'r') do |f|
        send_data f.read, filename: "Chowmill-Labels-Order-#{scheduler.id}.docx"
      end
      File.delete(save_path) if File.exist?(save_path)
    end
  end
end
