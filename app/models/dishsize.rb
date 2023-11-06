class Dishsize < ApplicationRecord
  belongs_to :address
  validates :serve_count, numericality: { greater_than_or_equal_to: 0}
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

  def as_json(options = nil)
    super({ only: [:id, :title, :description, :serve_count] }.merge(options || {}))
  end
end
