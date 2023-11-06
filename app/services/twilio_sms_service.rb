class TwilioSmsService < ApplicationService
  attr_reader :runningmenu_id, :restaurant_address_id, :sms_type

  def initialize(runningmenu_id=nil, restaurant_address_id, sms_type)
    @address = Address.find restaurant_address_id
    @sms_type = sms_type
    @time_zone = @address.addressable.time_zone
    if runningmenu_id.present?
      @runningmenu = Runningmenu.find runningmenu_id
      @items = @runningmenu.orders.active.where(restaurant_address_id: restaurant_address_id).sum(:quantity).to_i
      @pickup_time = @runningmenu.delivery? ? @runningmenu.delivery_at_timezone.strftime("%I:%M %p") : @runningmenu.pickup_at_timezone.strftime("%I:%M %p")
      @delivery_at = @runningmenu.delivery_at_timezone.to_time.strftime("%a. %b %d")
      @short_url_object = Shortener::ShortenedUrl.generate("#{ENV['VENDER_FRONTEND_HOST']}/dashboard/restaurant/#{@address.id}/meeting/#{@runningmenu.id}")
    end
  end

  def call
    message = get_message_text
    if message.present?
      puts "message: #{message}"
      @address.contact_numbers.each do |contact|
        SmsLog.create(from: ENV["RESTAURANTS_SMS_FROM"], to: contact.phone_number, body: message, name: contact.full_name, restaurant_id: @address.addressable.id, restaurant_address_id: @address.id)
      end
    end
  end

  def get_message_text
    message = nil
    case @sms_type
    when 'first'
      # First Notification
      message = "New Chowmill #{@runningmenu.delivery_type.capitalize} on #{@delivery_at} at #{@pickup_time} (Order # #{@runningmenu.id}). Details at https://cmill.co/#{@short_url_object.unique_key}"
    when 'cutoff'
      # Second Notification: At Cutoff
      message = "Cutoff Reached for Chowmill Order # #{@runningmenu.id}. #{@runningmenu.delivery_type.capitalize} on #{@delivery_at} at #{@pickup_time} for #{@items} item#{@items > 1 ? 's' : ''}. Details at https://cmill.co/#{@short_url_object.unique_key}" if @items > 0
    when 'cancelled'
      # Cancellation Notification: At Cancel Time
      cancelled_items = @runningmenu.orders.cancelled.where(restaurant_address_id: @address.id).sum(:quantity).to_i
      message = "Sorry, Chowmill Order # #{@runningmenu.id} (#{@delivery_at} at #{@pickup_time} | #{cancelled_items} item#{cancelled_items > 1 ? 's' : ''}) has been cancelled. Details at https://cmill.co/#{@short_url_object.unique_key}"
    when 'before_delivery'
      # 4pm Day Before Delivery
      items = @address.runningmenus.approved.where("DATE(runningmenus.delivery_at AT TIME ZONE '#{@time_zone}') = DATE(NOW() AT TIME ZONE '#{@time_zone}' + INTERVAL '1 day')").count
      tomorrow_date = Time.current.tomorrow.in_time_zone(@time_zone).strftime("%Y-%m-%d")
      short_url_meeting_object = Shortener::ShortenedUrl.generate("#{ENV['VENDER_FRONTEND_HOST']}/dashboard/restaurant/#{@address.id}/meetings?from=#{tomorrow_date}&to=#{tomorrow_date}")
      message = "Reminder: You have #{items} Chowmill order#{items > 1 ? 's' : ''} tomorrow. Please review all your orders at https://cmill.co/#{short_url_meeting_object.unique_key}"
    when 'on_delivery'
      # 7am Day of Delivery
      items = @address.runningmenus.approved.where("DATE(runningmenus.delivery_at AT TIME ZONE '#{@time_zone}') = DATE(NOW() AT TIME ZONE '#{@time_zone}')").count
      today_date = Time.current.in_time_zone(@time_zone).strftime("%Y-%m-%d")
      short_url_meeting_object = Shortener::ShortenedUrl.generate("#{ENV['VENDER_FRONTEND_HOST']}/dashboard/restaurant/#{@address.id}/meetings?from=#{today_date}&to=#{today_date}")
      message = "Reminder: You have #{items} Chowmill order#{items > 1 ? 's' : ''} today! Please review all your orders at https://cmill.co/#{short_url_meeting_object.unique_key}"
    when 'before_pickup'
      # 15 Minutes Before Pickup Time
      message = "Chowmill Order # #{@runningmenu.id} #{@runningmenu.delivery_type.capitalize} in 15 minutes for #{@items} item#{@items > 1 ? 's' : ''}. Details at https://cmill.co/#{@short_url_object.unique_key}"
    else
      puts 'wrong sms type passed'
    end
    return message
  end


end