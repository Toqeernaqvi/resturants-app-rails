class MenuBreakfast < Menu
  default_scope -> { where(menu_type: Menu.menu_types[:breakfast], status: Menu.statuses[:active]) }
  enum request_status: [:approved, :pending, :cancelled]
end
