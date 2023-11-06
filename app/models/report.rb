class Report < ApplicationRecord
  has_and_belongs_to_many :users
  enum report_type: [:orders_not_invoiced, :orders_not_billed, :average_take_rate]
  enum scheduled_period: [:hourly, :daily, :weekly, :monthly, :yearly]
  validates_presence_of :scheduled_period
  validates :scheduled_time, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 360}, if: lambda {|r| r.daily?}
  validates :scheduled_time, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 8640}, if: lambda {|r| r.hourly?}
  validates :scheduled_time, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 11}, if: lambda {|r| r.weekly?}
  validates :scheduled_time, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 50}, if: lambda {|r| r.monthly?}
  validates :scheduled_time, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 1}, if: lambda {|r| r.yearly?}

  def self.orders_not_invoiced
    orders = ReportsDbBase.connection.exec_query("SELECT * FROM ORDER_NOT_INVOICED_VIEW LIMIT 30;")
    if orders.present?
      report = Report.find_by_report_type(:orders_not_invoiced)
      if report.present?
        report.users.each do |user|
          begin
            email = ReportMailer.orders_not_invoiced(orders, user)
            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
          rescue StandardError => e
            if report.enable_error_logging
              email = ReportMailer.orders_not_invoiced(orders, user, e.message)
              EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
            end
          end
        end
      end
    end
  end

  def self.orders_not_billed
    orders = ReportsDbBase.connection.exec_query("SELECT * from ORDER_NOT_BILLED_VIEW LIMIT 30;")
    if orders.present?
      report = Report.find_by_report_type(:orders_not_billed)
      if report.present?
        report.users.each do |user|
          begin
            email = ReportMailer.orders_not_billed(orders, user)
            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
          rescue StandardError => e
            if report.enable_error_logging
              email = ReportMailer.orders_not_billed(orders, user, e.message)
              EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
            end
          end
        end
      end
    end
  end

  def self.average_take_rate
    start_date = (Time.current - 7.days).strftime('%Y-%m-%d')
    end_date = (Time.current).strftime('%Y-%m-%d')
    orders = ReportsDbBase.connection.exec_query("SELECT * from ORDERS_TOTAL_PAYOUT_VIEW WHERE DATE(date) BETWEEN '#{start_date}' AND '#{end_date}';")
    if orders.present?
      orders = orders.group_by{ |key, value| key["date"].to_date }
      report = Report.find_by_report_type(:average_take_rate)
      if report.present?
        report.users.each do |user|
          begin
            email = ReportMailer.average_take_rate(orders, user)
            EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
          rescue StandardError => e
            if report.enable_error_logging
              email = ReportMailer.average_take_rate(orders, user, e.message)
              EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
            end
          end
        end
      end
    end
  end
end
