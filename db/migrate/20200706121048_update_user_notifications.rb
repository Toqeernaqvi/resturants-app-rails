class UpdateUserNotifications < ActiveRecord::Migration[5.1]
  def change
    CompanyUser.active.where(cutoff_day_reminder_mail: false).update_all(cutoff_day_lunch_reminder: false, cutoff_day_dinner_reminder: false, cutoff_day_breakfast_reminder: false)
    CompanyUser.active.where(cutoff_hour_reminder_mail: false).update_all(cutoff_hour_lunch_reminder: false, cutoff_hour_dinner_reminder: false, cutoff_hour_breakfast_reminder: false)
  end
end
