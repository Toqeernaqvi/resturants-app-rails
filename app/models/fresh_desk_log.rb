class FreshDeskLog < ApplicationRecord
  enum widget_type: [:help, :menu]
end
