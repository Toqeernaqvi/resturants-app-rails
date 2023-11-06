class AddAdminCutoffReminderToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin_cutoff_hour_lunch_reminder, :boolean, default: :true
    add_column :users, :admin_cutoff_hour_dinner_reminder, :boolean, default: :true
    add_column :users, :admin_cutoff_hour_breakfast_reminder, :boolean, default: :true
    add_column :users, :admin_cutoff_day_lunch_reminder, :boolean, default: :true
    add_column :users, :admin_cutoff_day_dinner_reminder, :boolean, default: :true
    add_column :users, :admin_cutoff_day_breakfast_reminder, :boolean, default: :true
  end
end
