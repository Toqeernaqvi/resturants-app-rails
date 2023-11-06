class SundayShift < DriverShift
  default_scope -> { where(label: 'Sunday') }
end
