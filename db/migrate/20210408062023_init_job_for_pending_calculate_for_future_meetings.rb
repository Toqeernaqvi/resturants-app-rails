class InitJobForPendingCalculateForFutureMeetings < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where("delivery_at >= ?", Time.current).each do |runningmenu|
      runningmenu.set_user_pending_amount_job if runningmenu.user_pending_amount_job_id.blank?
    end
  end
end
