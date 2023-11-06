class AddTableLogsAttachments < ActiveRecord::Migration[5.1]
  def change
    create_table :logs_attachments do |t|
      t.references  :email_log, index: true, foreign_key: true
      t.string      :attachment
      t.string     :attachment_file_name
    end
  end
end
