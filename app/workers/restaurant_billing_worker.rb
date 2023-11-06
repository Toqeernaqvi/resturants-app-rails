class RestaurantBillingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :restaurant_billing

  def perform(runningmenu_id)
    runningmenu = Runningmenu.approved.find_by_id runningmenu_id
    if runningmenu.present?
      begin
        puts "Generate Restaurant Billing Job for runningmenu_id: #{runningmenu.id}"
        if runningmenu.orders.active.exists?
          RestaurantBilling.generate(runningmenu)
        end
        runningmenu.assign_attributes(restaurant_billing_job_status: Runningmenu.restaurant_billing_job_statuses[:processed], skip_set_dates: true, skip_set_jobs: true)
      rescue StandardError => e
        runningmenu.assign_attributes(restaurant_billing_job_status: Runningmenu.restaurant_billing_job_statuses[:not_processed], restaurant_billing_job_error: e.message, skip_set_dates: true, skip_set_jobs: true)
      end
      runningmenu.save(validate: false)
    end
  end
  
end