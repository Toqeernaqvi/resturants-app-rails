class BanAddress < ApplicationRecord
  belongs_to :company
  belongs_to :address

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

end
