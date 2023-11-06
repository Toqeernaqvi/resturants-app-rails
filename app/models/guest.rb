class Guest < ApplicationRecord
  has_one :order
  validates :first_name, :last_name, presence: true

  def name
    first_name.to_s + ' ' + last_name.to_s
  end
end