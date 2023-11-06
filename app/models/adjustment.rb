class Adjustment < ApplicationRecord
  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }
  enum adjustment_type: [:discount, :addition]
  # belongs_to :restaurant_billing
  belongs_to :adjustable, polymorphic: true
  validates :adjustment_date, :description, :price, presence: true
  validates :price, numericality: {:greater_than_or_equal_to => 0}
  after_create :set_billing_at_qb, if: lambda { |a| a.adjustable_type == 'RestaurantBilling' }
  after_save :set_dues
  after_destroy :set_dues

  def set_billing_at_qb
    self.adjustable.set_adjustment_calculation_at_qb(self.price)
  end

  def set_dues
    self.adjustable.calculate_total_dues if self.adjustable_type == 'Invoice'
    if self.adjustable_type == 'RestaurantBilling'
      self.adjustable.set_payout
      self.adjustable.save(validate: false)
    end
  end
end
