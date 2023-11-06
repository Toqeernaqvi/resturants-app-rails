class Nutrition < ApplicationRecord
  scope :newest, -> { where(parent_id: nil) }
  has_many :nutritional_facts, as: :factable, dependent: :destroy
  has_many :fooditems, through: :nutritional_facts, source: :factable, source_type: "Fooditem"
  has_many :options, through: :nutritional_facts, source: :factable, source_type: "Option"

  has_many :childs, -> { where("parent_id IS NOT NULL") }, foreign_key: :parent_id, class_name: 'Nutrition'
end
