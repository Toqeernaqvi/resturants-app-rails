class Fieldoption < ApplicationRecord
  #acts_as_paranoid

  belongs_to :field

  validates :name, presence: true
  enum status: [:active, :deleted]

  def as_json(options = nil)
    super({ only: [:id, :name]}.merge(options || {}))
  end
end
