class Sequence < ApplicationRecord
  #company addresses
  has_many :lunch_addresses, class_name: 'Address', foreign_key: :lunch_sequence_id
  has_many :dinner_addresses, class_name: 'Address', foreign_key: :dinner_sequence_id
  has_many :breakfast_addresses, class_name: 'Address', foreign_key: :breakfast_sequence_id
  has_many :buffet_addresses, class_name: 'Address', foreign_key: :buffet_sequence_id
  has_many :labels_seqs
  has_many :cuisines_sequences, through: :labels_seqs
  # validates_associated :cuisines_sequences
  accepts_nested_attributes_for :labels_seqs, allow_destroy: false
  # accepts_nested_attributes_for :cuisines_sequences, allow_destroy: true
  
  enum menu_type: [:lunch, :dinner, :breakfast, :buffet]
  validates :menu_type, presence: true
  validates :name, presence: true, uniqueness: true
  # validates :labels_seqs, presence: true
  enum status: [:active, :deleted]
  # around_save :catch_uniqueness_exception

  # private

  # def catch_uniqueness_exception
  #   yield
  # rescue ActiveRecord::RecordNotUnique
  #   self.errors.add(:base, "Cuisines are duplicated")
  # end

  after_create :create_labels

  def create_labels
    (1..self.restaurants_served).each do |num|
      self.labels_seqs.create(title: "Restaurant #{num}", position: num)
    end  
  end
end