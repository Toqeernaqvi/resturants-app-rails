class RestaurantSundayShift < RestaurantShift
  default_scope -> { where(label: 'Sunday') }
end
