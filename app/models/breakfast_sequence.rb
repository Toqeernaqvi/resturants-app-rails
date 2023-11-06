class BreakfastSequence < Sequence
  default_scope -> {where(menu_type: :breakfast)}
end