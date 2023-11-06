ActiveAdmin.register_page "Orders Not Billed" do
  menu false

  action_item :schedule_report do
    link_to "Schedule", admin_orders_not_billed_schedule_report_path, remote: true, class: 'scheduleReportBtn'
  end

  content do
    start_date = params[:start_date].present? ? params[:start_date] : Time.current.beginning_of_week.strftime('%Y-%m-%d')
    end_date = params[:end_date].present? ? params[:end_date] : Time.current.end_of_week.strftime('%Y-%m-%d')
    orders = ReportsDbBase.connection.exec_query("SELECT * from ORDER_NOT_BILLED_VIEW WHERE DATE(delivery_at) BETWEEN '#{start_date}' AND '#{end_date}';")
    # orders = orders.group_by{ |key, value| key["created_at"].to_date }
    render partial: 'admin/reports/orders_not_billed', locals: { orders: orders, start_date: start_date, end_date: end_date }
  end

  page_action :csv, method: :get do
    start_date = params[:start_date].present? ? params[:start_date] : Time.current.beginning_of_week.strftime('%Y-%m-%d')
    end_date = params[:end_date].present? ? params[:end_date] : Time.current.end_of_week.strftime('%Y-%m-%d')
    orders = ReportsDbBase.connection.exec_query("SELECT * from ORDER_NOT_BILLED_VIEW WHERE DATE(delivery_at) BETWEEN '#{start_date}' AND '#{end_date}';")
    # orders = orders.group_by{ |key, value| key["created_at"].to_date }
    csv = CSV.generate( encoding: 'UTF-8' ) do |csv|
      csv << [ "ID", "User", "Company", "Restaurant", "Address", "Fooditem", "Schedule", "Price", "Company Paid", "User Paid", "Markup", "Quantity", "Total Price", "Discount", "Discounted Total Price", "Delivery Date", "Delivery Instructions", "Invoice Id", "Status"]
      orders.each do |order|
        order_array = [ order["id"], order["user_name"], order["name"], order["restaurant_name"], order["company_location"], order["fooditem_name"],  order["runningmenu_id"], order["price"], order["company_price"], order["user_price"], order["site_price"], order["quantity"], order["total_price"], order["discount"], order["discounted_total_price"], (order["delivery_at"].to_time + Time.current.formatted_offset.to_time.hour.hours).strftime('%B %d, %Y %I:%M%P'), order["delivery_instructions"], order["invoice_id"], order["status"] ]
        csv << order_array
      end
    end

    send_data csv.encode('UTF-8'), type: 'text/csv; charset=utf-8; header=present', disposition: "attachment; filename=orders_not_billed_report.csv"
  end

  page_action :schedule_report, method: :get do
    @report = Report.find_by_report_type(Report.report_types[:orders_not_billed])
    respond_to do |format|
      format.js { render "admin/reports/schedule_report" }
    end
  end

  page_action :scheduled_report, method: :post do
    @report = Report.find_by_report_type(:orders_not_billed)
    if @report.present?
      if @report.update(name: params[:name], scheduled_period: Report.scheduled_periods[params["scheduled_period"]], scheduled_time: params[:scheduled_time].to_i, user_ids: params[:user_ids], enable_error_logging: params[:enable_error_logging])
        @success = true
        CronUpdaterJob.perform_later()
      else
        @success = false
      end
      render "admin/reports/schedule_report"
    else
      @report = Report.new(name: params[:name], scheduled_period: Report.scheduled_periods[params["scheduled_period"]], scheduled_time: params[:scheduled_time].to_i, user_ids: params[:user_ids], report_type: :orders_not_billed, enable_error_logging: params[:enable_error_logging])
      if @report.save
        @success = true
        CronUpdaterJob.perform_later()
      else
        @success = false
      end
      render "admin/reports/schedule_report"
    end
  end
end
