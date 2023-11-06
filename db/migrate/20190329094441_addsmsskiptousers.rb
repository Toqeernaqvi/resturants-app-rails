class Addsmsskiptousers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :sms_notification, :boolean, default: true, after: :phone_number
  end
end
