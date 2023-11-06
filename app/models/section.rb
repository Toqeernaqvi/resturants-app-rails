class Section < ApplicationRecord
  include Indexable
  #acts_as_paranoid

  searchkick callbacks: false, word_start: [:name, :description]
  scope :search_import, -> { where(status: :active) }
  attr_accessor :fooditem_id
  belongs_to :menu
  has_and_belongs_to_many :fooditems, dependent: :destroy
  validates :name, presence: true
  validates :section_type, presence: true, if: lambda{|s| s.menu.present? && s.menu.buffet? }
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  enum section_type: [:appetizer, :entrée, :vegetarian_entrée, :side, :dessert]
  after_save :update_status, if: lambda{|m| m.saved_change_to_parent_status?}

  after_save :relate_fooditem, if: lambda { |s| s.fooditem_id.present? }
  after_commit :index_elasticsearch
  
  def relate_fooditem
    fooditem = Fooditem.find self.fooditem_id
    fooditem.sections.destroy_all
    self.fooditems << fooditem
  end

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
end
