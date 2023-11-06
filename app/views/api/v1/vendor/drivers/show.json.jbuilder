json.extract! @driver, :id, :first_name, :last_name, :email, :phone_number, :car, :car_color, :car_licence_plate
json.monday_shifts @driver.monday_shifts do |shift|
	json.(
    shift,
    :id, :label#, :start_time, :end_time
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.tuesday_shifts @driver.tuesday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.wednesday_shifts @driver.wednesday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.thursday_shifts @driver.thursday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.friday_shifts @driver.friday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.saturday_shifts @driver.saturday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end
json.sunday_shifts @driver.sunday_shifts do |shift|
  json.(
    shift,
    :id, :label
  )
  json.start_time shift.start_time.strftime('%H:%M')
  json.end_time shift.end_time.strftime('%H:%M')
end