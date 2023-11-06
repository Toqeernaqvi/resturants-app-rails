class AddSurveyJobToFutureDeliveries < ActiveRecord::Migration[5.1]
  def change
    Runningmenu.approved.where('menu_type != ? AND hide_meeting = ?', Runningmenu.menu_types[:buffet], false).where("delivery_at > ?", Time.current).each do |runningmenu|
      runningmenu.set_survey_job
    end
  end
end
