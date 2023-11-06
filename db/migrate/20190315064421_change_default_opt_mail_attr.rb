class ChangeDefaultOptMailAttr < ActiveRecord::Migration[5.1]
  def up
    rename_column :users, :survery_mail, :survey_mail
    change_column :users, :survey_mail, :boolean, default: true
    change_column :users, :cutoff_day_reminder_mail, :boolean, default: true
    change_column :users, :cutoff_hour_reminder_mail, :boolean, default: true
  end
  def down
    change_column :users, :survery_mail, :boolean
    change_column :users, :cutoff_day_reminder_mail, :boolean
    change_column :users, :cutoff_hour_reminder_mail, :boolean
  end
end
