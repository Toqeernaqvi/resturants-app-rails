class OrderSurveyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :order_survey

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Order Survey Job for runningmenu_id: #{runningmenu.id}"
        if runningmenu.orders.active.joins(:restaurant).where("restaurants.name != ?", ENV['BEV_AND_MORE']).exists?
          Order.survey(runningmenu)
        end
        runningmenu.assign_attributes(survey_job_status: Runningmenu.survey_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.assign_attributes(survey_job_status: Runningmenu.survey_job_statuses[:not_processed], survey_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end
  
end