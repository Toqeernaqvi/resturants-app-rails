class GmenuLunch < Gmenu
  default_scope -> {where(menu_type: Gmenu.menu_types[:lunch])}
end
