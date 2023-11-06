class AddUserPendingAmountJobIdToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :user_pending_amount_job_id, :string
  end
end
