class AddColumnsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :survery_mail, :boolean
    add_column :users, :cutoff_day_reminder_mail, :boolean
    add_column :users, :cutoff_hour_reminder_mail, :boolean
  end
end
