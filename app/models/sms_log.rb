class SmsLog < ApplicationRecord
  belongs_to :restaurant, optional: true
  belongs_to :restaurant_address, optional: true

  enum status: [:pending, :sent, :failed, :cancelled]

  after_create_commit :after_create_commit

  def after_create_commit
    puts "Sending text mesg to #{self.to}"
    begin
      # sms = $twilio_client.messages.create(from: self.from, to: self.to, body: self.body, status_callback: ENV["BACKEND_HOST"]+"/admin/twilio_sms_status/webhook")
      sms = $twilio_client.messages.create(from: self.from, to: self.to, body: self.body)
      self.update_columns(sms_id: sms.sid, status: :sent)
      puts "Sent sms to #{self.to} i.e. #{sms.sid}"
    rescue StandardError => e
      self.update_columns(status: :failed, failed_reason: e.message)
    end
  end

  def created_at_timezone
    self.created_at.in_time_zone(self.restaurant.present? ? self.restaurant.time_zone : 'Pacific Time (US & Canada)')
  end
end