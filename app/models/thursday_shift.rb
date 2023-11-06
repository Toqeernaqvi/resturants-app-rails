class ThursdayShift < DriverShift
  default_scope -> { where(label: 'Thursday') }
end
