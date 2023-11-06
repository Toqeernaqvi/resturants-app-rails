json.address do
  json.id @restaurant.id
  json.address_name @restaurant.address_name
  json.enable_self_service @restaurant.enable_self_service
  json.billing_tab @restaurant.addressable.restaurant_billings.count > 0
  json.payout @restaurant.delayed_payout_days
  json.commission @restaurant.discount_percentage
  json.lunch_capacity @restaurant.lunch_order_capacity
  json.dinner_capacity @restaurant.dinner_order_capacity
  json.status  @restaurant.status
  json.address_line @restaurant.address_line
  json.street_number @restaurant.street_number
  json.street @restaurant.street
  json.suite_no @restaurant.suite_no
  json.city @restaurant.city
  json.state @restaurant.state
  json.zip @restaurant.zip
  json.logo @restaurant.logo.url
  json.delivery_radius @restaurant.delivery_radius
  json.delivery_cost @restaurant.delivery_cost
  json.individual_meals_cutoff @restaurant.individual_meals_cutoff
  json.buffet_cutoff @restaurant.buffet_cutoff
  json.restaurant_name @restaurant.addressable.name
  json.cuisines @restaurant.addressable.cuisines do |cuisine|
    json.id cuisine.id
    json.name cuisine.name
  end

  json.contacts @restaurant.contacts do |contact|
    json.id contact.id
    json.cname contact.name
    json.phone_number contact.phone_number
    json.email contact.email
    json.fax contact.fax
    json.email_label_check contact.email_label_check
    json.fax_summary_check contact.fax_summary_check
    json.email_summary_check contact.email_summary_check
    json.send_text_reminders contact.send_text_reminders
  end
  json.schedules do
    json.monday @restaurant.monday_shifts do |monday_shift|
      json.id monday_shift.id
      json.label monday_shift.label
      json.start_time monday_shift.start_time.strftime('%H:%M')
      json.end_time monday_shift.end_time.strftime('%H:%M')
    end
    json.tuesday @restaurant.tuesday_shifts do |tuesday_shift|
      json.id tuesday_shift.id
      json.label tuesday_shift.label
      json.start_time tuesday_shift.start_time.strftime('%H:%M')
      json.end_time tuesday_shift.end_time.strftime('%H:%M')
    end
    json.wednesday @restaurant.wednesday_shifts do |wednesday_shift|
      json.id wednesday_shift.id
      json.label wednesday_shift.label
      json.start_time wednesday_shift.start_time.strftime('%H:%M')
      json.end_time wednesday_shift.end_time.strftime('%H:%M')
    end
    json.thursday @restaurant.thursday_shifts do |thursday_shift|
      json.id thursday_shift.id
      json.label thursday_shift.label
      json.start_time thursday_shift.start_time.strftime('%H:%M')
      json.end_time thursday_shift.end_time.strftime('%H:%M')
    end
    json.friday @restaurant.friday_shifts do |friday_shift|
      json.id friday_shift.id
      json.label friday_shift.label
      json.start_time friday_shift.start_time.strftime('%H:%M')
      json.end_time friday_shift.end_time.strftime('%H:%M')
    end
    json.saturday @restaurant.saturday_shifts do |saturday_shift|
      json.id saturday_shift.id
      json.label saturday_shift.label
      json.start_time saturday_shift.start_time.strftime('%H:%M')
      json.end_time saturday_shift.end_time.strftime('%H:%M')
    end
    json.sunday @restaurant.sunday_shifts do |sunday_shift|
      json.id sunday_shift.id
      json.label sunday_shift.label
      json.start_time sunday_shift.start_time.strftime('%H:%M')
      json.end_time sunday_shift.end_time.strftime('%H:%M')
    end
  end

end
