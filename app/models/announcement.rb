class Announcement < ApplicationRecord
  validates :title, :expiration, presence: true
  enum status: [:active, :deleted]
end
