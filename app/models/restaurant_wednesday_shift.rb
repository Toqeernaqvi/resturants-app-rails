class RestaurantWednesdayShift < RestaurantShift
  default_scope -> { where(label: 'Wednesday') }
end
