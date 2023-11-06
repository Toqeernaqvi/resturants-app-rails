class SaturdayShift < DriverShift
  default_scope -> { where(label: 'Saturday') }
end
