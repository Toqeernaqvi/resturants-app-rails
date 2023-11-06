# class FaxWorker
#   include Sidekiq::Worker
#   sidekiq_options queue: :fax

#   def perform(faxlog_id)
#     faxlog = Faxlog.find faxlog_id
#     puts "Fax Job for faxlog_id: #{faxlog.id}"
#     faxlog.deliver_pending
#   end
# end