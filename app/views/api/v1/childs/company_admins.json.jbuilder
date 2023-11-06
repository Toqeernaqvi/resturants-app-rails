json.extract! @company, :id, :name, :status, :user_meal_budget, :time_zone
json.company_admins @company_admins do |company_admin|
  json.(
    company_admin,
    :id, :first_name, :last_name, :email, :phone_number, :desk_phone, :time_zone
  )
end