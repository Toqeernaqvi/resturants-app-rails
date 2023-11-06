class CuisinesSequence < ApplicationRecord
  belongs_to :cuisineslist
  belongs_to :labels_seq

  validates :cuisineslist_id, presence: true
  # validates_uniqueness_of :cuisineslist_id, scope: :labels_seq_id

  delegate :title, to: :labels_seq
end