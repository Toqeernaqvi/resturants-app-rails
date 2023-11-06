class DinnerSequence < Sequence
  default_scope -> {where(menu_type: :dinner)}
end