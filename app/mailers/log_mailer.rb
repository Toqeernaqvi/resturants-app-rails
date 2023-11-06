class LogMailer < ApplicationMailer
  require 'open-uri'
  def send_log_mails(log_email)
    begin
      if log_email.logs_attachments.present?
        log_email.logs_attachments.each do |attach_file|
          attachments[attach_file.attachment_file_name] = open(URI.escape(ENV["CLOUDFRONT_URL"]+"/"+attach_file.attachment)).read
        end
        mail(from: "Chowmill <#{log_email.sender}>", to: log_email.recipient , subject: log_email.subject, cc: log_email.cc.present? ? log_email.cc : "") do |format|
          format.html { render html: Base64.decode64(log_email.body).html_safe }
        end
      else
        mail(from:  "Chowmill <#{log_email.sender}>", to: log_email.recipient , subject: log_email.subject, cc: log_email.cc.present? ? log_email.cc : "", body: Base64.decode64(log_email.body), content_type: 'text/html; charset=UTF-8')
      end
      log_email.update(sent_at: Time.current, status: :sent)
    rescue StandardError => e
      puts "*************EMAIL FAILED DUE TO REASON : #{e.message}*************"
      log_email.update(failed_at: Time.current, status: :failed)
    end
  end
end
