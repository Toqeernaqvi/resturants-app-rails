class AddChargePendingAmountJobIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :charge_pending_amount_job_id, :string
  end
end
