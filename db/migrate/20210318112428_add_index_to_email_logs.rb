class AddIndexToEmailLogs < ActiveRecord::Migration[5.1]
  def change
    add_index :email_logs, :status
  end
end
