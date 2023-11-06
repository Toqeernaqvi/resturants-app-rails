class AddAttachmentToLogsAttachments < ActiveRecord::Migration[5.1]
  def change
    EmailLog.all.each do |e|
      if e.attachment.present? && e.attachment_file_name.present?
        e.logs_attachments.create(attachment: e.attachment, attachment_file_name: e.attachment_file_name)
      end
    end
  end
end
