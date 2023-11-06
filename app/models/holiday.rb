class Holiday < ApplicationRecord
  default_scope -> {where("end_date >= '#{Time.current.to_date}'")}
  belongs_to :address
  validates :start_date, :end_date, presence: true
  validates_uniqueness_of :start_date, :end_date, scope: :address_id
  validate :end_date_after_start_date?, if: lambda {|h| h.start_date.present? && h.end_date.present? }

  def end_date_after_start_date?
    if end_date < start_date
      errors.add :end_date, "must be after start date"
    end
  end
end