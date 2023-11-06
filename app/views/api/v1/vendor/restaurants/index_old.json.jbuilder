json.restaurant_name @restaurant.name
json.cuisines @restaurant.cuisines do |cuisine|
  json.id cuisine.id
  json.name cuisine.name
end

json.addresses @restaurants.each do |restaurant|
  json.id restaurant.id
  json.name restaurant.adress_name_format
  json.enable_self_service restaurant.enable_self_service
  json.payout restaurant.delayed_payout_days
  json.Commission restaurant.discount_percentage
  json.lunch_capacity restaurant.lunch_order_capacity
  json.dinner_capacity restaurant.dinner_order_capacity
  json.status  restaurant.status
  json.address_line restaurant.address_line
  json.street restaurant.street_number
  json.street restaurant.street
  json.suite_no restaurant.suite_no
  json.city restaurant.city
  json.state restaurant.state
  json.zip restaurant.zip
  json.order_presence Order.active.where(created_at: current_member.last_sign_in_at..current_member.current_sign_in_at, restaurant_address_id: restaurant.id).exists?
  json.logo restaurant.logo.url
  json.delivery_radius restaurant.delivery_radius
  json.delivery_cost restaurant.delivery_cost
  json.individual_meals_cutoff restaurant.individual_meals_cutoff
  json.buffet_cutoff restaurant.buffet_cutoff
  json.stripe_connected restaurant.stripe_details_submitted

  json.contacts restaurant.contacts.order(name: :asc) do |contact|
    json.id contact.id
    json.cname contact.name
    json.phone_number contact.phone_number
    json.email contact.email
    json.fax contact.fax
    json.email_label_check contact.email_label_check
    json.fax_summary_check contact.fax_summary_check
    json.email_summary_check contact.email_summary_check
  end
  json.schedules do
    json.monday restaurant.monday_shifts do |monday_shift|
      json.id monday_shift.id
      json.label monday_shift.label
      json.start_time monday_shift.start_time.strftime('%H:%M')
      json.end_time monday_shift.end_time.strftime('%H:%M')
    end
    json.tuesday restaurant.tuesday_shifts do |tuesday_shift|
      json.id tuesday_shift.id
      json.label tuesday_shift.label
      json.start_time tuesday_shift.start_time.strftime('%H:%M')
      json.end_time tuesday_shift.end_time.strftime('%H:%M')
    end
    json.wednesday restaurant.wednesday_shifts do |wednesday_shift|
      json.id wednesday_shift.id
      json.label wednesday_shift.label
      json.start_time wednesday_shift.start_time.strftime('%H:%M')
      json.end_time wednesday_shift.end_time.strftime('%H:%M')
    end
    json.thursday restaurant.thursday_shifts do |thursday_shift|
      json.id thursday_shift.id
      json.label thursday_shift.label
      json.start_time thursday_shift.start_time.strftime('%H:%M')
      json.end_time thursday_shift.end_time.strftime('%H:%M')
    end
    json.friday restaurant.friday_shifts do |friday_shift|
      json.id friday_shift.id
      json.label friday_shift.label
      json.start_time friday_shift.start_time.strftime('%H:%M')
      json.end_time friday_shift.end_time.strftime('%H:%M')
    end
    json.saturday restaurant.saturday_shifts do |saturday_shift|
      json.id saturday_shift.id
      json.label saturday_shift.label
      json.start_time saturday_shift.start_time.strftime('%H:%M')
      json.end_time saturday_shift.end_time.strftime('%H:%M')
    end
    json.sunday restaurant.sunday_shifts do |sunday_shift|
      json.id sunday_shift.id
      json.label sunday_shift.label
      json.start_time sunday_shift.start_time.strftime('%H:%M')
      json.end_time sunday_shift.end_time.strftime('%H:%M')
    end
    # json.id shift.id
    # json.label shift.label
    # json.start_time shift.start_time
    # json.end_time shift.end_time
    # json.(
    #   restaurant, :lunch_order_capacity, :dinner_order_capacity,
    #   :monday_first_start_time, :monday_second_start_time,
    #   :monday_first_end_time, :monday_second_end_time,
    #   :tuesday_first_start_time, :tuesday_second_start_time,
    #   :tuesday_first_end_time, :tuesday_second_end_time,
    #   :wednesday_first_start_time, :wednesday_first_end_time,
    #   :wednesday_second_start_time, :wednesday_second_end_time,
    #   :thursday_first_start_time, :thursday_first_end_time,
    #   :thursday_second_start_time, :thursday_second_end_time,
    #   :friday_first_start_time, :friday_first_end_time,
    #   :friday_second_start_time, :friday_second_end_time,
    #   :saturday_first_start_time, :saturday_first_end_time,
    #   :saturday_second_start_time, :saturday_second_end_time,
    #   :sunday_first_start_time, :sunday_first_end_time,
    #   :sunday_second_start_time, :sunday_second_end_time,
    #   :notes )
  end

end
