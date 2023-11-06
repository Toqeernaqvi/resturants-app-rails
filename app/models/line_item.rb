class LineItem < ApplicationRecord
  belongs_to :invoice
  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }
  validates_numericality_of :quantity, :unit_price, :amount, :discount, :greater_than_or_equal_to => 0
  attr_accessor :default_line_item

  after_save :set_invoice_dues, if: lambda { |i| i.saved_change_to_amount? || i.saved_change_to_discount? }
  after_save :set_invoice_at_qb, if: lambda { |i| (i.saved_change_to_amount? || i.saved_change_to_discount? || i.saved_change_to_item?) && default_line_item.blank? }

  
  def set_invoice_dues
    self.invoice.calculate_total_dues
  end

  def set_invoice_at_qb
    self.invoice.set_calculation_at_qb(self.invoice)
  end

end