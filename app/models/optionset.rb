class Optionset < ApplicationRecord
  #acts_as_paranoid

  belongs_to :menu
  has_many :options, dependent: :destroy
  has_and_belongs_to_many :fooditems, dependent: :destroy
  accepts_nested_attributes_for :options, allow_destroy: true

  validates :name, :start_limit, :end_limit, presence: true
  validates :start_limit, :end_limit, numericality: {greater_than_or_equal_to: 0}, unless: lambda {|o| o.will_save_change_to_status? || o.will_save_change_to_parent_status?}
  validate :end_limit_less_than_start_limit
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  attr_accessor :fooditem_id, :add_fooditem

  after_save :update_status, if: lambda{|m| m.saved_change_to_parent_status?}
  after_save :relate_fooditem, if: lambda { |s| s.fooditem_id.present? }
  
  def update_status
    if self.parent_status_active?
      self.active!
    else
      self.deleted!
    end
  end

  def relate_fooditem
    fooditem = Fooditem.find self.fooditem_id
    if self.add_fooditem.present? && !self.fooditems.exists?(id: fooditem.id)
      self.fooditems << fooditem
    else
      Optionset.find_by_sql("DELETE FROM fooditems_optionsets AS fos WHERE fos.fooditem_id = #{fooditem.id} AND fos.optionset_id = #{self.id}") if self.add_fooditem.blank?
    end
  end

  def end_limit_less_than_start_limit
    if start_limit.present? && end_limit < start_limit
      errors.add(:end_limit, "can't less than start limit")
    end
  end

  def as_json(options = nil)
    super({ only: [:id, :description, :required, :start_limit, :end_limit] }.merge(options || {}))
  end
end
