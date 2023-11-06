class Fooditem < ApplicationRecord
  include Indexable
  #acts_as_paranoid
  acts_as_ordered_taggable

  searchkick callbacks: false, word_start: [:name, :description]
  scope :search_import, -> { where(status: :active) }

  belongs_to :menu
  has_and_belongs_to_many :dietaries, dependent: :destroy
  has_and_belongs_to_many :ingredients, dependent: :destroy
  has_and_belongs_to_many :sections, dependent: :destroy
  has_and_belongs_to_many :optionsets, dependent: :destroy
  has_many :dishsize_fooditems, dependent: :destroy
  has_many :dishsizes, through: :dishsize_fooditems

  has_many :nutritional_facts, as: :factable, dependent: :destroy
  has_many :nutritions, -> { where("nutritions.parent_id IS NULL").select("nutritional_facts.id AS id, nutritions.id AS nutrition_id, nutritions.name, nutritional_facts.value ") }, through: :nutritional_facts
  accepts_nested_attributes_for :dishsize_fooditems, allow_destroy: true
  accepts_nested_attributes_for :nutritional_facts
  has_many :ratings, as: :ratingable
  has_many :orders
  has_many :favorites, as: :favoritable
  attr_accessor :del_img, :skip_nutritional_facts

  mount_uploader :image, FooditemUploader

  validates :name, presence: true
  validates_numericality_of :price, :greater_than => 0, :on => :save
  # validates :calories, numericality: {greater_than_or_equal_to: 0}, unless: lambda {|f| f.will_save_change_to_status? || f.will_save_change_to_parent_status?}
  validates :price, presence: true
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_save :update_status, if: lambda{|m| m.saved_change_to_parent_status?}
  after_save :init_nutritional_facts, if: lambda { |f| !f.nutritional_facts.exists? && f.skip_nutritional_facts.blank? }
  after_commit :upload_to_s3, if: lambda { |f| f.image.blank? && f.file_url.present? }
  after_commit :index_elasticsearch

  def update_status
    if self.parent_status_active?
      self.active!
    else
      self.deleted!
    end
  end

  def should_index?
    status # only index active records
  end

  def init_nutritional_facts
    Nutrition.order(id: :asc).each do |nutrition|
      self.nutritional_facts.create(nutrition_id: nutrition.id, value: nutrition.name == 'Calories' ? self.calories : 0.0)
    end
  end

  def restaurant_name
    self.menu&.address&.addressable&.name
  end

  def upload_to_s3
    FooditemImageUploadToS3Job.perform_later(self, self.file_url)
  end

  def as_json(options = nil)
    super({ only: [
      :id,
      :name,
      :description,
      :price,
      :gross_price,
      :spicy,
      :best_seller,
      :skip_markup,
      :rating_count,
      :average_rating,
      :image
    ], methods: [:nutritions, :restaurant_name]}.merge(options || {}))
  end
end
