class DriversChannel < ApplicationCable::Channel
  def subscribed
    stream_from "drivers_#{params[:driver_id]}_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    # $redis.del("driver_#{params["user_id"]}_online") unless params["user_id"].blank?
  end

  def send_message(data)
    puts "####################################################------------------####################"
    driver = Driver.find data["driver_id"]
    driver.sms_broadcast(data["message"])
  end
end