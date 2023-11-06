class CompaniesSchedule < ApplicationRecord
  belongs_to :address
  belongs_to :restaurant_address, class_name: "RestaurantAddress"
  belongs_to :labels_seq
  belongs_to :cuisines_sequence
  belongs_to :addresses_cuisineslist

  validates :address_id, :cuisines_sequence_id, :addresses_cuisineslist_id, :restaurant_address_id, :delivery_date, presence: true
end