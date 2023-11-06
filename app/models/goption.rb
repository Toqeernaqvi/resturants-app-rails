class Goption < ApplicationRecord
  #acts_as_paranoid

  belongs_to :goptionset
  has_and_belongs_to_many :dietaries
  has_and_belongs_to_many :ingredients

  validates :description, :price, presence: true
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_save :update_status, if: lambda{|m| m.saved_change_to_parent_status?}

  def update_status
    if self.parent_status_active?
      self.active!
    else
      self.deleted!
    end
  end
end
