# class MailerProcessorJob < ApplicationJob
#   queue_as :mailer_deliver

#   def perform(opts)
#     LogMailer.send_log_mails(opts).deliver_now
#   end
# end
