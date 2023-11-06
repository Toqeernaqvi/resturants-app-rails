class FridayShift < DriverShift
  default_scope -> { where(label: 'Friday') }
end
