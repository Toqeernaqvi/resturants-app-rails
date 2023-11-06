class CuisinesRecurringMenu < ApplicationRecord
  belongs_to :cuisine
  belongs_to :recurring_scheduler
  enum status: [:active, :deleted]
end