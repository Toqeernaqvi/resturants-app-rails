class Faxlog < ApplicationRecord
  enum status: [:pending, :delivered, :resent]
  validates :from, :to, presence: true

  DELAY = ENV["TWILIO_FAX_DELAY_MINUTES"].to_i

  # after_save :set_fax_job, if: lambda { |f| Rails.env.production? && f.pending? && f.saved_change_to_retry_time? && f.retry_time > Time.current && f.tries < 4 }

  # def set_fax_job
  #   if self.fax_job_id.present?
  #     job = Sidekiq::ScheduledSet.new.find_job(self.fax_job_id)
  #     job.delete unless job.nil?
  #   end
  #   job_id = FaxWorker.perform_at(self.retry_time.utc, self.id)
  #   self.update_column(:fax_job_id, job_id)
  # end

  # def deliver_pending
  #   # @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  #   fax = $twilio_client.fax.faxes.create(from: self.from,to: self.to, media_url: ENV["S3_BUCKET_URL"]+"/"+self.media_url, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_fax_status/webhook")
  #   self.update_columns(sid: fax.sid, tries: self.tries.succ) if fax.sid.present?
  # end

  # def self.deliver_pending
  #   @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
  #   if Rails.env.production?
  #     pending_faxes = Faxlog.pending.where("tries < ? AND retry_time < ?",4, Time.current)
  #     pending_faxes.each do |faxlog|
  #       fax = @client.fax.faxes.create(from: faxlog.from,to: faxlog.to, media_url: ENV["S3_BUCKET_URL"]+"/"+faxlog.media_url, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_fax_status/webhook")
  #       faxlog.update_columns(sid: fax.sid, tries: faxlog.tries.succ) if fax.sid.present?
  #     end
  #   end
  # end

end
