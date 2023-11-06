class AddAttributesToSmsLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :sms_logs, :sms_id, :string
    add_column :sms_logs, :name, :string
    add_reference :sms_logs, :restaurant
    add_reference :sms_logs, :restaurant_address
    remove_column :sms_logs, :time_zone, :string
  end
end
