class RestaurantThursdayShift < RestaurantShift
  default_scope -> { where(label: 'Thursday') }
end
