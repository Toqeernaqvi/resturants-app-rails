class TuesdayShift < DriverShift
  default_scope -> { where(label: 'Tuesday') }
end
