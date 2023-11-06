class RestaurantMondayShift < RestaurantShift
  default_scope -> { where(label: 'Monday') }
end
