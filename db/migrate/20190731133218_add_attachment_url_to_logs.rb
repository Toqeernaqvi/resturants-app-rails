class AddAttachmentUrlToLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :email_logs, :attachment, :string
    add_column :email_logs, :attachment_file_name, :string
  end
end
