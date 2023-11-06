class TwilioSmsJob < ApplicationJob
  queue_as :twilio_sms

  def perform(runningmenu_id, address_id, sms_type)
    puts "Twilio sms job start for #{{runningmenu_id: runningmenu_id, restaurant_address_id: address_id, sms_type: sms_type}}"
    TwilioSmsService.call(runningmenu_id, address_id, sms_type)
    puts "Twilio sms job end for #{{runningmenu_id: runningmenu_id, restaurant_address_id: address_id, sms_type: sms_type}}"
  end
end
