class AddressesCuisineslist < ApplicationRecord
  belongs_to :address
  belongs_to :cuisineslist

  validates :address_id, presence: true
  validates_uniqueness_of :address_id, scope: :cuisineslist_id
end