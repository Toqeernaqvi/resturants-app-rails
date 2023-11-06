class VenderMenu < ApplicationRecord
  belongs_to :address
  has_many :sections, dependent: :destroy
  has_many :fooditems, dependent: :destroy
  has_many :optionsets, dependent: :destroy

  accepts_nested_attributes_for :sections, allow_destroy: true
  accepts_nested_attributes_for :fooditems, allow_destroy: true
  accepts_nested_attributes_for :optionsets, allow_destroy: true

  enum menu_type: [:dont_care, :lunch, :dinner, :breakfast]
  enum spicy: [:no, :yes], _prefix: :spicy
  enum best_seller: [:no, :yes], _prefix: :best_seller
  enum status: [:pending, :approved]
  
end
