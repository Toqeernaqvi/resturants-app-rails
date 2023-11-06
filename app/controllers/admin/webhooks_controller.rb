class Admin::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  require 'action_view'
  include ActionView::Helpers::NumberHelper
  def receive
    puts "Webhook: Email Start"
    if params[:data].present?
      data = {}
      runningmenu = Runningmenu.find_by_task_id(params[:data][:task][:id])
      if runningmenu.present? && !runningmenu.task_status_completed?
        hour_before_delivery_at = runningmenu.delivery_at - 1.hour
        hour_ahead_delivery_at = runningmenu.delivery_at + 1.hour
        if (hour_before_delivery_at..hour_ahead_delivery_at).cover?(Time.current)
          food_is_here(runningmenu)
        end
        runningmenu.update_columns(task_completed: true, task_status: :completed, completion_time: Time.current)
        data = {currently_at: runningmenu.company.name, pickup_task: false}
      elsif !runningmenu.present?
        addresses_runningmenu = AddressesRunningmenu.find_by(restaurant_task_id: params[:data][:task][:id])
        if addresses_runningmenu.present?
          addresses_runningmenu.update_columns(task_status: :completed)
          runningmenu = addresses_runningmenu.runningmenu
          data = {currently_at: addresses_runningmenu.address.addressable.name, pickup_task: true}
        else
          runningmenu = Runningmenu.find_by(pickup_task_id: params[:data][:task][:id])
          if runningmenu.present?
            runningmenu.update_columns(pickup_task_status: :completed)
            data = {currently_at: ENV['BEV_AND_MORE'], beverages_task: ENV['BEV_AND_MORE'], beverages_task_status: runningmenu.pickup_task_status, pickup_task: true}
          end
        end
      end
      if runningmenu.present?
        data[:runningmenu_id] = runningmenu.id
        data[:slug] = runningmenu.slug
        addresses = []
        runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: :not_created).order(task_status: :desc).uniq.each do |address_runningmenu|
          addresses.push({restaurant: address_runningmenu.address.addressable.name, task_status: address_runningmenu.task_status})
        end
        data[:addresses] = addresses
        data[:destination] = {name: runningmenu.company.name, task_status: runningmenu.task_status, arriving_at: nil, completion_time: runningmenu.completion_time}
        driver = runningmenu.driver
        if driver.present?
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + driver.phone_number, car: driver.car, car_color: driver.car_color, car_license_plate: driver.car_licence_plate, driver_image: driver.image.present? ? driver.image.url : nil} : nil
        else
          driver = Onfleet::Worker.get(params["data"]["task"]["worker"])
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + number_to_phone(driver.phone.gsub('+1', '')), car: driver.vehicle.description, car_color: driver.vehicle.color, car_license_plate: driver.vehicle.license_plate, driver_image: nil} : nil
        end
        ActionCable.server.broadcast "driver_track_#{runningmenu.id}_channel", data: data
        render status: 200, json: 'broadcasting drivers channel'.to_json
      else
        render status: 200, json: 'no schedular found to send email'.to_json
      end
    end
    puts "Webhook: Email End"
  end

  def food_is_here(runningmenu)
    users = User.active.where(id: runningmenu.orders.active.pluck('user_id').uniq)
    guests_orders = runningmenu.orders.where("guest_id is not null or share_meeting_id is not null").uniq.group_by{ |o| Guest.find_by_id(o["guest_id"]) or ShareMeeting.find_by_id(o["share_meeting_id"])}
    if guests_orders.present?
      guests_orders.each do |user, guest_orders|
        email = ScheduleMailer.onfleet_delivery_mail(user, runningmenu, guest_orders, true)
        EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
      end
    end
    users.each do |user|
      email = ScheduleMailer.onfleet_delivery_mail(user, runningmenu)
      EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
    end
  end

  def validate
    render :json => params[:check] if params[:check].present?
  end

  def sms_receive
    begin
      driver = Driver.find_by_phone_number params["From"].gsub("+1","").unpack('A3A3A4').join('-')
      user_name = driver.present? ? driver.name : params["From"]
      notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'], username: user_name
      notifier.ping params['Body']
    rescue StandardError => e
      puts "Driver message failed to send to slack due to #{e.message}"
    end
    render :json=>{message: "ok"}
  end

  def restaurants_sms
    begin
      phone_number = params["From"].gsub("+1","").unpack('A3A3A4').join('-')
      resource = RestaurantAdmin.active.find_by_phone_number(phone_number) || Contact.find_by_phone_number(phone_number)
      if resource.present?
        update_notification_setting(resource) if params["OptOutType"].present?
        restaurant_names = SmsLog.sent.joins(:restaurant).where(to: params['From']).order(id: :desc).pluck("restaurants.name").uniq
        user_name = "#{resource.name} (#{restaurant_names.first}) - #{params['From']}"
        if restaurant_names.count > 1
          user_name = "#{resource.name} (#{restaurant_names.first} + #{restaurant_names.count} more) - #{params['From']}"
        end
      else
        user_name = params['From']
      end
      notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_RESTAURANTS_URL'], username: user_name
      notifier.ping params['Body']
    rescue StandardError => e
      puts "Restaurant message failed to send to slack due to #{e.message}"
    end
    render :json=>{message: "ok"}
  end

  def update_notification_setting(resource)
    puts "SMS NOTIFICATION SETTING START #{resource.inspect}: #{params['OptOutType']}"
    Rails.logger.debug("SMS NOTIFICATION SETTING: #{resource.inspect}: #{params['OptOutType']}")
    if ['cancel', 'end', 'quit', 'stop', 'stopall', 'unsubscribe'].include?(params["OptOutType"]&.downcase)
      resource.update_column(:send_text_reminders, false)
    elsif ['start', 'unstop', 'yes'].include?(params["OptOutType"]&.downcase)
      resource.update_column(:send_text_reminders, true)
    end
    puts "SMS NOTIFICATION SETTING END"
  end

  # def sms_status_callback
  #   sms_log = SmsLog.find_by_sms_id params["SmsSid"]
  #   if sms_log.present?
  #     sms_log.update(status: params["SmsStatus"])
  #   end
  #   render :json=>{message: "sms webhook completed"}
  # end

  # def fax_status_callback
  #   faxlog = Faxlog.find_by_sid params["FaxSid"]
  #   if faxlog.present?
  #     if params["Status"] == "delivered"
  #       faxlog.update(status: Faxlog.statuses["delivered"])
  #     elsif params["Status"] == "failed"
  #       email = ScheduleMailer.fax_failed(faxlog, params["Status"], params["ErrorMessage"])
  #       EmailLog.create(sender: ENV['RECIPIENT_EMAIL'], subject: email.subject, recipient: email.to.first, body: Base64.encode64(email.body.raw_source))
  #     elsif ["no-answer","busy"].include?(params["Status"])
  #       last_fax_time = Faxlog.pending.where(to: faxlog.to).pluck(:retry_time).compact.max
  #       retry_time = Time.current
  #       retry_time = last_fax_time if last_fax_time.present? && last_fax_time > Time.current
  #       new_retry_time = retry_time+Faxlog::DELAY.minutes
  #       faxlog.update(retry_time: new_retry_time)
  #     end
  #   end
  #   render :json=>{message: "fax webhook completed"}
  # end

  def freshdesk_ticket_receive
    ticket = $zendesk_client.tickets.find!(:id => params[:webhook][:ticket_id]) rescue nil
    unless ticket.nil?
      attachments = []
      widget_type = nil
      ticket.comments.each do |c|
        c[:attachments].each_with_index do |attachment, index|
          attachments << "#{index+1}. <a href='#{attachment.content_url}'>#{attachment.file_name}</a>"
        end
      end
      if ticket.via["channel"] == "api"
        widget_type = FreshDeskLog.widget_types[FreshDeskLog.widget_types.keys[0]]
      else
        widget_type = FreshDeskLog.widget_types[FreshDeskLog.widget_types.keys[1]]
      end
      FreshDeskLog.create!(ticketidentity: ticket.id,
      widget_type: widget_type,
      name: params[:webhook][:requester_name],
      email: params[:webhook][:requester_email],
      subject: ticket.subject,
      description: ticket.description.split("\n\n")[0],
      ticket_url: ticket.url,
      requester: params[:webhook][:user_id],
      attachment: attachments.join("</br>"))
    end
    render :json=>{message: "webhook funtionality completed"}
  end

  def quickbooks_oauth_callback
    if params[:state].present?
      # use the state value to retrieve from your backend any information you need to identify the customer in your system
      redirect_uri = ENV['BACKEND_HOST']+"/admin/quickbooks_oauth/webhook"
      # redirect_uri = "http://94a1de3f6dbd.ngrok.io/admin/quickbooks_oauth/webhook"
      begin
        if resp = $oauth2_client.auth_code.get_token(params[:code], redirect_uri: redirect_uri)
          # save your tokens here. For example: # quickbooks_credentials.update_attributes(access_token: resp.token, refresh_token: resp.refresh_token, realm_id: params[:realmId])
          setting = Setting.latest
          access_token = OAuth2::AccessToken.new($oauth2_client, resp.token, refresh_token: resp.refresh_token)
          new_access_token_object = access_token.refresh!
          setting.update_columns(token: new_access_token_object.token, refresh_token: new_access_token_object.refresh_token, token_expires_at: Time.at(new_access_token_object.expires_at).to_datetime, realmid: params[:realmId])
          redirect_to admin_settings_path, notice: "Quickbook has been connected successfully"
        end
      rescue StandardError => e
        redirect_to admin_settings_path, alert: "Quickbook connection failed #{e.message}"
      end
    end
  end

  def task_started
    if params.present?
      data = {}
      if params["data"]["task"]["pickupTask"] && params["data"]["task"]["notes"].include?("Pickup utensils & do inventory of meals.")
        address_runningmenu = AddressesRunningmenu.find_by_restaurant_task_id(params["data"]["task"]["id"])
        if address_runningmenu.present?
          address_runningmenu.update_columns(task_status: :started) unless address_runningmenu.arrived?
          runningmenu = address_runningmenu.runningmenu
          data = {currently_at: address_runningmenu.address.addressable.name, pickup_task: true}
        end
      elsif params["data"]["task"]["pickupTask"]
        runningmenu = Runningmenu.find_by_pickup_task_id params["data"]["task"]["id"]
        if runningmenu.present?
          runningmenu.update_columns(pickup_task_status: :started) unless runningmenu.pickup_task_arrived?
          data = {currently_at: ENV['BEV_AND_MORE'], beverages_task: ENV['BEV_AND_MORE'], beverages_task_status: runningmenu.pickup_task_status, pickup_task: true}
        end
      else
        runningmenu = Runningmenu.find_by_task_id params["data"]["task"]["id"]
        if runningmenu.present?
          runningmenu.update_columns(task_status: :started) unless runningmenu.task_status_arrived?
          data = {currently_at: runningmenu.company.name, pickup_task: false}
        end
      end
      if runningmenu.present?
        data[:runningmenu_id] = runningmenu.id
        data[:slug] = runningmenu.slug
        addresses = []
        runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: :not_created).order(task_status: :desc).uniq.each do |address_runningmenu|
          addresses.push({restaurant: address_runningmenu.address.addressable.name, task_status: address_runningmenu.task_status})
        end
        data[:addresses] = addresses
        data[:destination] = {name: runningmenu.company.name, task_status: runningmenu.task_status, arriving_at: runningmenu.arriving_at}
        driver = runningmenu.driver
        if driver.present?
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + driver.phone_number, car: driver.car, car_color: driver.car_color, car_license_plate: driver.car_licence_plate, driver_image: driver.image.present? ? driver.image.url : nil} : nil
        else
          driver = Onfleet::Worker.get(params["data"]["task"]["worker"])
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + number_to_phone(driver.phone.gsub('+1', '')), car: driver.vehicle.description, car_color: driver.vehicle.color, car_license_plate: driver.vehicle.license_plate, driver_image: nil} : nil
        end
        ActionCable.server.broadcast "driver_track_#{runningmenu.id}_channel", data: data
      end
    end
    render status: 200, json: 'Driver task started'.to_json
  end

  def driver_eta
    if params.present?
      runningmenu = Runningmenu.find_by_task_id params["data"]["task"]["id"]
      if runningmenu.present?
        addresses = []
        runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: :not_created).order(task_status: :desc).uniq.each do |address_runningmenu|
          addresses.push({restaurant: address_runningmenu.address.addressable.name, task_status: address_runningmenu.task_status})
        end
        data = {currently_at: runningmenu.company.name, driver_eta: Time.at(params[:etaSeconds]).strftime("%-M"), pickup_task: false, runningmenu_id: runningmenu.id, addresses: addresses, destination: {name: runningmenu.company.name, task_status: runningmenu.task_status, arriving_at: runningmenu.arriving_at}}
        runningmenu.update_column(:arriving_at, data[:driver_eta]&.to_i)
        driver = runningmenu.driver
        if driver.present?
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + driver.phone_number, car: driver.car, car_color: driver.car_color, car_license_plate: driver.car_licence_plate, driver_image: driver.image.present? ? driver.image.url : nil} : nil
        else
          driver = Onfleet::Worker.get(params["data"]["task"]["worker"])
          data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + number_to_phone(driver.phone.gsub('+1', '')), car: driver.vehicle.description, car_color: driver.vehicle.color, car_license_plate: driver.vehicle.license_plate, driver_image: nil} : nil
        end
        ActionCable.server.broadcast "driver_track_#{runningmenu.id}_channel", data: data
      end
    end
    render status: 200, json: 'Driver is arriving'.to_json
  end

  def driver_arrival
    if params.present?
      data = {}
      if params["data"]["task"]["pickupTask"] && params["data"]["task"]["notes"].include?("Pickup utensils & do inventory of meals.")
        address_runningmenu = AddressesRunningmenu.find_by_restaurant_task_id(params["data"]["task"]["id"])
        if address_runningmenu.present?
          address_runningmenu.update_columns(task_status: :arrived)
          runningmenu = address_runningmenu.runningmenu
          data = {currently_at: address_runningmenu.address.addressable.name, pickup_task: true}
        end
      elsif params["data"]["task"]["pickupTask"]
        runningmenu = Runningmenu.find_by_pickup_task_id params["data"]["task"]["id"]
        if runningmenu.present?
          runningmenu.update_columns(pickup_task_status: :arrived)
          data = {currently_at: ENV['BEV_AND_MORE'], beverages_task: ENV['BEV_AND_MORE'], beverages_task_status: runningmenu.pickup_task_status, pickup_task: true}
        end
      else
        runningmenu = Runningmenu.find_by_task_id params["data"]["task"]["id"]
        if runningmenu.present?
          runningmenu.update_columns(task_status: :arrived)
          data = {currently_at: runningmenu.company.name, pickup_task: false}
        end
      end
    end
    if runningmenu.present?
      data[:runningmenu_id] = runningmenu.id
      data[:slug] = runningmenu.slug
      addresses = []
      runningmenu.addresses_runningmenus.joins(:address).where.not(task_status: :not_created).order(task_status: :desc).uniq.each do |address_runningmenu|
        addresses.push({restaurant: address_runningmenu.address.addressable.name, task_status: address_runningmenu.task_status})
      end
      data[:addresses] = addresses
      data[:destination] = {name: runningmenu.company.name, task_status: runningmenu.task_status, arriving_at: runningmenu.arriving_at}
      driver = runningmenu.driver
      if driver.present?
        data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + driver.phone_number, car: driver.car, car_color: driver.car_color, car_license_plate: driver.car_licence_plate, driver_image: driver.image.present? ? driver.image.url : nil} : nil
      else
        driver = Onfleet::Worker.get(params["data"]["task"]["worker"])
        data[:driver] = driver.present? ? {name: driver.name, ph_number: '1-' + number_to_phone(driver.phone.gsub('+1', '')), car: driver.vehicle.description, car_color: driver.vehicle.color, car_license_plate: driver.vehicle.license_plate, driver_image: nil} : nil
      end
      ActionCable.server.broadcast "driver_track_#{runningmenu.id}_channel", data: data
    end
    render status: 200, json: 'Driver arrived'.to_json
  end

end
