class RestaurantFridayShift < RestaurantShift
  default_scope -> { where(label: 'Friday') }
end
