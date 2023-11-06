class DriverTrackChannel < ApplicationCable::Channel
  def subscribed
    if current_login_user && params["meetingId"].present?
      stream_from "driver_track_#{params["meetingId"]}_channel"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
