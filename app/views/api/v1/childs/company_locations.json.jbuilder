json.extract! @company, :id, :name, :status, :user_meal_budget, :time_zone
json.locations @locations do |location|
  json.(
    location,
    :id, :address_name, :city, :state, :zip, :suite_no, :delivery_instructions, :time_zone
  )
  json.address_line "#{location.street_number} "+ location.street.to_s
  json.city_state_zip location.city.to_s + ", " + location.state.to_s + " " + location.zip.to_s
end