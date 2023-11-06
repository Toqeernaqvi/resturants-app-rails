class SetCutoffReminderForFutureMeetings < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.individual.where("delivery_at > ? AND cutoff_at > ? AND hide_meeting = ? AND (cutoff_hour_before_job_id IS NULL OR cutoff_day_before_job_id IS NULL)", Time.current, Time.current, false).each do |runningmenu|
      runningmenu.set_cutoff_reminder_job
    end
  end
end
