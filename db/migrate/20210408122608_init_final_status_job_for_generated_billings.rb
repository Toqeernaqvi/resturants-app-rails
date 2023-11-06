class InitFinalStatusJobForGeneratedBillings < ActiveRecord::Migration[5.1]
  def change
    RestaurantBilling.active.where(payment_status: [RestaurantBilling.payment_statuses[:generated], RestaurantBilling.payment_statuses[:final]]).each do |billing|
      billing.set_final_status_job if billing.generated? && billing.final_status_job_id.blank?
      billing.set_due_status_job if billing.final? && billing.due_status_job_id.blank?
    end
  end
end
