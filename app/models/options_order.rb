class OptionsOrder < ApplicationRecord
  #acts_as_paranoid

  belongs_to :optionsets_order
  belongs_to :option
  belongs_to :order, optional: true

  before_create :initialize_attributes

  def initialize_attributes
    self.order_id = self.optionsets_order.order_id
  end
end
