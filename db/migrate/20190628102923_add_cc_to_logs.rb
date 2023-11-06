class AddCcToLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :email_logs, :cc, :string, after: :recipient
  end
end
