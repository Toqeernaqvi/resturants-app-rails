class AddJobIdToEmailLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :email_logs, :job_id, :string
  end
end
