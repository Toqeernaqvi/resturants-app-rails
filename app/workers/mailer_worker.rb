class MailerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :deliver_email

  def perform(email_id)
    puts "Sending email_id: #{email_id}"
    email_log = EmailLog.find email_id
    LogMailer.send_log_mails(email_log).deliver_now
  end
end