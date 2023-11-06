class Approver < ApplicationRecord
  belongs_to :billing
  has_many :addresses, as: :addressable, dependent: :destroy
  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a 'example@example.com ' " }, allow_blank: true
  accepts_nested_attributes_for :addresses, allow_destroy: true

  def as_json(options = nil)
    super({ only: [
      :id,
      :name,
      :email,
    ]}.merge(options || {}))
  end
end
