class AddJobsStatusToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :charge_pending_amount_job_status, :integer, default: 0
    add_column :users, :charge_pending_amount_job_error, :string
  end
end
