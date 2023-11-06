class Orderfield < ApplicationRecord
  belongs_to :order
  belongs_to :company, optional: true
  belongs_to :field
  belongs_to :fieldoption, optional: true

  enum field_type: [:dropdown, :text]
  before_save :initialize_attributes

  def initialize_attributes
    self.company = self.order.company
    self.field_type = self.field.field_type
  end
end
