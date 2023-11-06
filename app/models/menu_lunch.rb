class MenuLunch < Menu
  default_scope -> {where(menu_type: Menu.menu_types[:lunch], status: Menu.statuses[:active])}
  enum request_status: [:approved, :pending, :cancelled]
end
