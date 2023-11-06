class Billing < ApplicationRecord

  enum invoice_credit_card: [:invoice, :credit_card]
  belongs_to :company
  has_many :approvers
  accepts_nested_attributes_for :approvers, allow_destroy: true
  has_many :addresses, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :addresses
  validates_length_of :cvc, :minimum => 3, if: lambda { |b| b.credit_card? && b.cvc.present?}
  validates_format_of :card_number,
  :with => /[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}/,
  :message => "- Card numbers must be in xxxx-xxxx-xxxx-xxxx format.", if: lambda { |b| b.credit_card? && b.card_number.present?}
  validates :expiry_month, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 12}, if: lambda { |b| b.credit_card? && b.expiry_month.present?}
  validates :expiry_year, numericality: {greater_than_or_equal_to: 1900, less_than_or_equal_to: 2050}, if: lambda { |b| b.credit_card? && b.expiry_year.present?}
  validates :delivery_fee, numericality: {:greater_than_or_equal_to => 0}
  after_validation :stripe_credit_card_payment, if: lambda { |b| (b.credit_card? && ((b.change_card.present? && b.change_card == '1') || b.will_save_change_to_token? || (b.change_card.present? && !b.change_card == '1') || b.updated_from_backend))}
  attr_accessor :card_number, :cvc, :expiry_month, :expiry_year, :change_card, :updated_from_backend
  attr_accessor :delete_stripe_card


  def stripe_credit_card_payment
    begin
      if self.token.present? && !(self.change_card.present? && self.change_card == '1')
        token = self.token
      else
        tk = Stripe::Token.create({
          card: {
            number: self.card_number,
            exp_month: self.expiry_month,
            exp_year: self.expiry_year,
            cvc: self.cvc,
          },
        })
      end
      if tk.present?
        token = tk.id
        self.stripe_cc_id = tk.card.id
      end
      if token.present?
        self.token = token
        customer = Stripe::Customer.create({
          description: self.company.name, # removed "Customer for"
          source: token
        })
        if customer.present?
          self.customer_id = customer.id
        end
      end
    rescue Stripe::CardError => e
      errors.add(:card_number, "Credit Card failed to save due to #{e.message}")
    rescue => e
      errors.add(:card_number, "Credit Card failed to save due to #{e.message}")
    end
  end

  def as_json(options = nil)
    super({ only: [
      :id,
      :invoice_credit_card,
      :name,
    ]}.merge(options || {}))
  end

  def retreive_card
    card = nil
    details = Stripe::Token.retrieve(
      self.token
    )
    card = details.card if details.present?
  end

  def remove_card
    card_id = self.retreive_card&.id
    result = Stripe::Customer.delete_source(
            self.customer_id,
            card_id
          )
    self.update_columns(token: nil, customer_id: nil) if result.deleted
  end
  
end
