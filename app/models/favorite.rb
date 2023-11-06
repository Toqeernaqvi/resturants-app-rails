class Favorite < ApplicationRecord
  belongs_to :favoritable, polymorphic: true
  belongs_to :company
  belongs_to :user
  belongs_to :fooditem, foreign_type: 'Fooditem', foreign_key: 'favoritable_id', optional: true

  validates_uniqueness_of :favoritable_id, :message => "Favorites already created", scope: :user_id
end  