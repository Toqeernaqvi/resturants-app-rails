class RestaurantTuesdayShift < RestaurantShift
  default_scope -> { where(label: 'Tuesday') }
end
