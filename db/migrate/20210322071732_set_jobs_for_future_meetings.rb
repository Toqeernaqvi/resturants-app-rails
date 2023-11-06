class SetJobsForFutureMeetings < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where("delivery_at >= ? AND cutoff_at > ? AND admin_cutoff_at > ?", Time.current, Time.current, Time.current).each do |runningmenu|
      runningmenu.set_cutoff_job
      runningmenu.set_admin_cutoff_reached_job
      runningmenu.set_buffet_delivery_reminder_job if runningmenu.buffet?
    end
  end
end
