class AddTimeZoneToSmsLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :sms_logs, :time_zone, :string
  end
end
