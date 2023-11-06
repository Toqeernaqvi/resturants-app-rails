class GmenuBreakfast < Gmenu
  default_scope -> {where(menu_type: Gmenu.menu_types[:breakfast])}
end
