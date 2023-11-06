class BuffetSequence < Sequence
  default_scope -> {where(menu_type: :buffet)}
end