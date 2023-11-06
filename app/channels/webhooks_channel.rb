class WebhooksChannel < ApplicationCable::Channel
  def subscribed
    stream_from "webhooks_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end