class Cuisineslist < ApplicationRecord
  has_many :addresses_cuisineslists

  validates_associated :addresses_cuisineslists
  accepts_nested_attributes_for :addresses_cuisineslists, allow_destroy: true
  
  validates :name, presence: true, uniqueness: true
  enum menu_type: [:lunch, :dinner, :breakfast, :buffet]
  validates :addresses_cuisineslists, presence: true
  enum status: [:active, :deleted]

  around_save :catch_uniqueness_exception

  private

  def catch_uniqueness_exception
    yield
  rescue ActiveRecord::RecordNotUnique
    self.errors.add(:base, "Restaurants are duplicated")
  end
end