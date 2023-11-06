class WednesdayShift < DriverShift
  default_scope -> { where(label: 'Wednesday') }
end
