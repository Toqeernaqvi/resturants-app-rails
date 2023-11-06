json.extract! @company, :id, :name, :status, :user_meal_budget, :time_zone
json.childs @company.childs.active do |child|
  json.(
    child,
    :id, :name, :status, :user_meal_budget, :time_zone
  )
end