class MondayShift < DriverShift
  default_scope -> { where(label: 'Monday') }
end
