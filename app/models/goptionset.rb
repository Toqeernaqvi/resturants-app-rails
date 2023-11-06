class Goptionset < ApplicationRecord
  #acts_as_paranoid

  belongs_to :gmenu
  has_many :goptions, dependent: :destroy
  has_and_belongs_to_many :gfooditems, dependent: :destroy
  accepts_nested_attributes_for :goptions, allow_destroy: true

  validates :name, :start_limit, :end_limit, presence: true
  validate :end_limit_less_than_start_limit
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

  def end_limit_less_than_start_limit
    if start_limit.present? && end_limit < start_limit
      errors.add(:end_limit, "can't less than start limit")
    end
  end
end
