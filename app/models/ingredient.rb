class Ingredient < ApplicationRecord
  include Indexable
  #acts_as_paranoid

  searchkick callbacks: false, word_start: [:name]
  scope :search_import, -> { where(status: :active) }

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  # has_and_belongs_to_many :fooditems
  # has_and_belongs_to_many :restaurants

  validates :name, presence: true, uniqueness: true
  enum status: [:active, :deleted]
  enum parent_status: [:active, :deleted], _prefix: :parent_status

  after_commit :index_elasticsearch

  def should_index?
    status # only index active records
  end

end
