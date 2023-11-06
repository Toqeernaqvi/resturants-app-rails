ActiveAdmin.register_page "Average Take Rate" do
  menu false

  action_item :schedule_report do
    link_to "Schedule", admin_average_take_rate_schedule_report_path, remote: true, class: 'scheduleReportBtn'
  end

  content do
    start_date = params[:start_date].present? ? params[:start_date] : Time.current.beginning_of_week.strftime('%Y-%m-%d')
    end_date = params[:end_date].present? ? params[:end_date] : Time.current.end_of_week.strftime('%Y-%m-%d')
    exclude_no_markup = params[:exclude_no_markup].present? && params[:exclude_no_markup] == "on" ?  true : false
    orders = ReportsDbBase.connection.exec_query("SELECT * from ORDERS_TOTAL_PAYOUT_VIEW WHERE #{exclude_no_markup ? 'skip_markup = false' : 'true'} AND DATE(date) BETWEEN '#{start_date}' AND '#{end_date}';")
    orders = orders.group_by{ |key, value| key["date"].to_date }
    render partial: 'admin/reports/average_take_rate', locals: { orders: orders, start_date: start_date, end_date: end_date, exclude_no_markup: exclude_no_markup }
  end

  page_action :schedule_report, method: :get do
    @report = Report.find_by_report_type(Report.report_types[:average_take_rate])
    respond_to do |format|
      format.js { render "admin/reports/schedule_report" }
    end
  end

  page_action :scheduled_report, method: :post do
    @report = Report.find_by_report_type(:average_take_rate)
    if @report.present?
      if @report.update(name: params[:name], scheduled_period: Report.scheduled_periods[params["scheduled_period"]], scheduled_time: params[:scheduled_time].to_i, user_ids: params[:user_ids], enable_error_logging: params[:enable_error_logging])
        @success = true
        CronUpdaterJob.perform_later()
      else
        @success = false
      end
      render "admin/reports/schedule_report"
    else
      @report = Report.new(name: params[:name], scheduled_period: Report.scheduled_periods[params["scheduled_period"]], scheduled_time: params[:scheduled_time].to_i, user_ids: params[:user_ids], report_type: :average_take_rate, enable_error_logging: params[:enable_error_logging])
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
