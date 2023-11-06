class DishsizeFooditem < ApplicationRecord
  belongs_to :dishsize
  belongs_to :fooditem
  validates :price, numericality: { greater_than_or_equal_to: 0}
  validates :price, presence: true
  validate :dishsize_uniqueness, if: lambda{|df| df.dishsize_id_changed?}

  def dishsize_uniqueness
    if self.fooditem.dishsizes.pluck(:id).include?(self.dishsize_id)
      errors.add(:base, "Same dishsizes cannot be attached more than one time to fooditem.")
    end
  end
end
