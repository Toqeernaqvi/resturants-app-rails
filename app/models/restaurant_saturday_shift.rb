class RestaurantSaturdayShift < RestaurantShift
  default_scope -> { where(label: 'Saturday') }
end
