class DietariesUser < ApplicationRecord
  belongs_to :dietary
  belongs_to :user
  enum status: [:active, :deleted]
end
