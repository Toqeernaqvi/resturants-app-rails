class AddCompanyRefToPaymentLogs < ActiveRecord::Migration[5.1]
  def change
    add_reference :payment_logs, :company, foreign_key: true, after: :user_id
  end
end
