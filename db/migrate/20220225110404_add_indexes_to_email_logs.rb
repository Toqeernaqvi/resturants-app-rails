class AddIndexesToEmailLogs < ActiveRecord::Migration[5.1]
  def change
    add_index :email_logs, :sender
    add_index :email_logs, :recipient
    add_index :email_logs, :subject
    add_index :email_logs, :cc
  end
end
