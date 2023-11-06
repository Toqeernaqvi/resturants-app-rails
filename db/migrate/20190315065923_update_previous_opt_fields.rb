class UpdatePreviousOptFields < ActiveRecord::Migration[5.1]
  def change
    User.all.each do |user|
      user.survey_mail = 1
      user.cutoff_day_reminder_mail = 1
      user.cutoff_hour_reminder_mail = 1
      user.save!
    end
  end
end
