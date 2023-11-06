class Option < ApplicationRecord
  #acts_as_paranoid

  belongs_to :optionset
  has_and_belongs_to_many :dietaries
  has_and_belongs_to_many :ingredients

  has_many :nutritional_facts, as: :factable, dependent: :destroy
  has_many :nutritions, -> { where("nutritions.parent_id IS NULL").select("nutritional_facts.id AS id, nutritions.id AS nutrition_id, nutritions.name, nutritional_facts.value ") }, through: :nutritional_facts
  
  validates :description, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0}
  # validates :calories, numericality: {greater_than_or_equal_to: 0}, unless: lambda {|o| o.will_save_change_to_status? || o.will_save_change_to_parent_status?}
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  attr_accessor :skip_nutritional_facts

  accepts_nested_attributes_for :nutritional_facts
  
  after_save :update_status, if: lambda{|m| m.saved_change_to_parent_status?}
  after_save :init_nutritional_facts, if: lambda { |f| !f.nutritional_facts.exists? && f.skip_nutritional_facts.blank? }

  def update_status
    if self.parent_status_active?
      self.active!
    else
      self.deleted!
    end
  end

  def init_nutritional_facts
    Nutrition.order(id: :asc).each do |nutrition|
      self.nutritional_facts.create(nutrition_id: nutrition.id, value: nutrition.name == 'Calories' ? self.calories : 0.0)
    end
  end

  def as_json(options = nil)
    super({ only: [:id, :description, :price] }.merge(options || {}))
  end
end
