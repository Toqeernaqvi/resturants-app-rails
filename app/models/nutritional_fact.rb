class NutritionalFact < ApplicationRecord
  default_scope { order(id: :asc) }

  belongs_to :factable, polymorphic: true
  belongs_to :nutrition
  validates_uniqueness_of :nutrition, scope: :factable
  validates :value, numericality: {greater_than_or_equal_to: 0}
end