class GmenuDinner < Gmenu
  default_scope -> {where(menu_type: Gmenu.menu_types[:dinner])}
end
