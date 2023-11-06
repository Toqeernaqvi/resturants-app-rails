class ScheduleMailer < ApplicationMailer

  def schedule_ready(user, runningmenu)
    @runningmenu = runningmenu
    mail(to: user.email , subject: "#{@runningmenu.runningmenu_type.capitalize} Menu is Ready for #{@runningmenu.runningmenu_name} (#{@runningmenu.delivery_at_timezone.to_time.strftime('%B %d, %Y')})")
  end

  def cutoff_at_reached(runningmenus)
    @runningmenus = runningmenus
    mail(to: ENV['ORDERS_EMAIL'] , subject: "Cutoff Reached for #{runningmenus.map{|c| c.company_id}.uniq.count} Companies at #{Time.current.in_time_zone("Pacific Time (US & Canada)").strftime('%I:%M%P')}")
  end

  def onfleet_delivery_mail(user, runningmenu, guest_orders = nil, guest = false)
    @runningmenu = runningmenu
    @user = user
    @guest_orders = guest_orders
    @guest = guest
    mail(to: user.email , subject: "Your Food is Here!")
  end

  def onfleet_task_failed(runningmenu, subject, error)
    @runningmenu = runningmenu
    @error = error
    mail(to: ENV['ORDERS_EMAIL'] , subject: subject)
  end

  def schedule_placed(runningmenu)
    @runningmenu = runningmenu
    subject = @header = (@runningmenu.company.enable_marketplace && !@runningmenu.created_from_frontend.blank?) ? "New Marketplace Delivery Scheduled" : "New Meeting Request"
    mail(to: ENV['ORDERS_EMAIL'] , subject: subject)
  end

  def cancel_scheduler(runningmenu)
    @runningmenu = runningmenu
    subject = @header = "Cancelled Delivery Request: #{@runningmenu.runningmenu_name}"
    mail(to: ENV['ORDERS_EMAIL'] , subject: subject)
  end

  def schedule_updated_from_frontend(runningmenu, fields_changes, version, user)
    @version = version
    @runningmenu = runningmenu
    @field_changes = fields_changes
    @user = user
    mail(to: ENV['ORDERS_EMAIL'] , subject: "Update Meeting Request: #{@runningmenu.runningmenu_name}")
  end

  def share(share_meeting)
    @runningmenu = share_meeting.runningmenu
    @admin = share_meeting.user
    @token = share_meeting.token
    mail(to: share_meeting.email , subject: "Select Your #{@runningmenu.runningmenu_type.capitalize} for #{@runningmenu.runningmenu_name.capitalize}")
  end

  def set_common_subject(runningmenu, orders)
    if runningmenu.pickup?
      "Chowmill Order #{runningmenu.id} | #{orders.sum{|o| o.quantity}} Items | Pickup #{runningmenu.pickup_at_timezone.strftime('%A, %B %d, %Y')} at #{runningmenu.pickup_at_timezone.strftime("%I:%M %p")}"
    else
      "Chowmill Order #{runningmenu.id} | #{orders.sum{|o| o.quantity}} Items | Delivery #{runningmenu.delivery_at_timezone.strftime('%A, %B %d, %Y')} at #{runningmenu.delivery_at_timezone.strftime("%I:%M %p")}"
    end
  end

  def orders_for_restaurants_buffet_reminder(runningmenu, orders, address, contacts)
    @runningmenu = runningmenu
    @orders = orders
    @address = address
    @contact = false
    subject = set_common_subject(runningmenu, orders)
    if contacts.present?
      to_email = contacts.first
      cc_contacts = contacts.drop(1)
      @contact = true
      mail(to: to_email, from: ENV['ORDERS_EMAIL'], cc: cc_contacts, subject: "REMINDER: "+subject)
    else
      mail(to: ENV['ORDERS_EMAIL'], from: ENV['ORDERS_EMAIL'], subject: "REMINDER: "+subject)
    end
  end

  def changes_to_restaurant(runningmenu, orders, address, to_email, cc_contacts, title)
    @runningmenu = runningmenu
    @orders = orders
    @address = address
    @contact = false
    @title = title
    total_quantity = @orders.sum{|q| q.quantity}
    # @items = runningmenu.cancelled? ? total_quantity : total_quantity - Order.cancelled.where(:id=>@orders.pluck(:order_ids)).sum{|q| q.quantity}
    @items = total_quantity
    if runningmenu.cancelled?
      subject = "Sorry! #{address.addressable.name} No Longer Scheduled"
    else
      subject = "[Chowmill Order # #{@runningmenu.id}] #{title} Chowmill #{runningmenu.delivery_type.titleize} on #{@runningmenu.delivery_at_timezone.strftime('%a. %b. %d')} | #{@items} Items"
    end
    if to_email.present?
      @contact = true
      mail(to: to_email, from: ENV['ORDERS_EMAIL'], cc: cc_contacts, subject: subject)
    else
      mail(to: ENV['ORDERS_EMAIL'], from: ENV['ORDERS_EMAIL'], subject: subject)
    end
  end

  def no_changes(runningmenu, to_email, address, cc_contacts)
    @runningmenu = runningmenu
    @address = address
    mail(to: to_email, cc: cc_contacts, subject: "Sorry! #{@address.addressable.name} No Longer Scheduled")
  end

  def recurring_failure(recurring_scheduler, errors)
    @recurring_scheduler = recurring_scheduler
    @errors = errors
    @recurring_scheduler_id = recurring_scheduler.id
    @address = recurring_scheduler.address.address_line
    @company = recurring_scheduler.company.name
    mail(to: ENV['ORDERS_EMAIL'] , subject: "Recurring Meetings Creation Failed: #{@company}")
  end

  def fax_failed(faxlog, status, error)
    @faxlog = faxlog
    @error = error
    @status = status
    subject = "Fax Delivery failed for #{faxlog.file_name.split(".pdf").last}"
    mail(to: ENV['ORDERS_EMAIL'] , subject: subject)
  end

  def orders_status(runningmenu, restaurant_address, accepted, message)
    @runningmenu = runningmenu
    @restaurant = restaurant_address.addressable
    @items = runningmenu.orders.active.where(restaurant_address_id: restaurant_address.id).sum(:quantity).to_i
    # @time = runningmenu.pickup? ? runningmenu.pickup_time(restaurant_address) : runningmenu.delivery_at_timezone.strftime("%I:%M %p")
    @time = runningmenu.pickup? ? runningmenu.pickup_at_timezone.strftime("%I:%M %p") : runningmenu.delivery_at_timezone.strftime("%I:%M %p")
    @restaurant_contact = runningmenu.pickup? ? OpenStruct.new({phone_number: '(408) 883-9415', email: 'support@chowmill.com'}) : restaurant_address.contact_card
    to = runningmenu.delivery? ? runningmenu.user.email : ENV['ORDERS_EMAIL']
    @accepted = accepted
    @message = message
    mail(to: to , subject: "#{@restaurant.name} has #{@accepted ? 'accepted' : 'rejected'} your order on #{runningmenu.delivery_at_timezone.strftime('%a. %b %d')}, #{@time} for #{@items} Items (Order # #{@runningmenu.id})")
  end

  def upcoming_orders(meetings, admin_addresses,restaurant_admin)
    @user = restaurant_admin
    @admin_addresses = admin_addresses.uniq.join(',')
    @meetings = meetings
    @pickups = meetings.keys.map { |k| k.to_date }
    @restaurant_image_url = "#{ENV['CLOUDFRONT_URL']}/icons/blue-store-solid.png"
    @decline_arrow = "#{ENV['CLOUDFRONT_URL']}/icons/arrow-trend-down-solid.png"
    @rise_arrow = "#{ENV['CLOUDFRONT_URL']}/icons/arrow-trend-up-solid.png"
    mail(to: @user.email, from: ENV['ORDERS_EMAIL'], subject: "Upcoming Orders For Next week")
  end

end
