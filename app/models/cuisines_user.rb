class CuisinesUser < ApplicationRecord
  belongs_to :cuisine
  belongs_to :user
  enum status: [:active, :deleted]
end
