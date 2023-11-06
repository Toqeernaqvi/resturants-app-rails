class LunchSequence < Sequence
  default_scope -> {where(menu_type: :lunch)}
end