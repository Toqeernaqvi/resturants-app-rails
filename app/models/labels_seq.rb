class LabelsSeq < ApplicationRecord
  belongs_to :sequence
  has_many :cuisines_sequences

  validates_associated :cuisines_sequences
  accepts_nested_attributes_for :cuisines_sequences, allow_destroy: true

  validates :title, presence: true

  delegate :name, to: :sequence
  delegate :restaurants_served, to: :sequence

  around_save :catch_uniqueness_exception

  private

  def catch_uniqueness_exception
    yield
  rescue ActiveRecord::RecordNotUnique
    self.errors.add(:base, "Cuisines are duplicated")
  end

end