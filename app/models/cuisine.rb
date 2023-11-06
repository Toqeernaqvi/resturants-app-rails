class Cuisine < ApplicationRecord
  include Indexable
  #acts_as_paranoid

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  searchkick callbacks: false, word_start: [:name]
  scope :search_import, -> { where(status: :active) }

  has_many :cuisines_restaurants
  has_many :restaurants, through: :cuisines_restaurants
  #has_many :cuisines_requests
  #has_many :runningmenu_requests, through: :cuisines_requests
  #has_many :runningmenus, through: :cuisines_requests
  has_many :cuisines_users
  has_many :users, through: :cuisines_users
  has_many :cuisines_menus
  has_many :runningmenus, through: :cuisines_menus

  validates :name, presence: true, uniqueness: true
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status
  after_commit :index_elasticsearch
  
  def should_index?
    status # only index active records
  end
end
