class OptionsetsOrder < ApplicationRecord
  #acts_as_paranoid

  belongs_to :order
  belongs_to :optionset

  has_many :options_orders, dependent: :destroy
  has_many :options, through: :options_orders
  accepts_nested_attributes_for :options_orders, allow_destroy: true
end
