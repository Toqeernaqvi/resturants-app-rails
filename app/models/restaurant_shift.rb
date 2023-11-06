class RestaurantShift < ApplicationRecord
  
  belongs_to :address, optional: true
  validates :start_time, :end_time, presence: true

  before_validation :set_dates_as_utc, unless: lambda { |rs| rs.new_record? }
  after_create :set_dates_as_utc_new

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }
  attr_accessor :time_zone
  validate :end_time_is_after_start_time

  def start_time_timezone
    self.start_time.in_time_zone(self.address.addressable.time_zone)
  end

  def end_time_timezone
    self.end_time.in_time_zone(self.address.addressable.time_zone)
  end

  def set_dates_as_utc
    if self.address.updated_from_frontend.blank? && self.start_time.present? && self.end_time.present?
      st = self.start_time
      et = self.end_time
      self.start_time = DateTime.new.in_time_zone(self.address.addressable.time_zone).change(year: st.year, month: st.month, day: st.day, hour: st.hour, min: st.min, sec: st.sec)
      self.end_time = DateTime.new.in_time_zone(self.address.addressable.time_zone).change(year: et.year, month: et.month, day: et.day, hour: et.hour, min: et.min, sec: et.sec)
    end
  end

  def set_dates_as_utc_new
    if self.address.updated_from_frontend.blank? && self.start_time.present? && self.end_time.present?
      st = self.start_time
      et = self.end_time
      start_time = DateTime.new.in_time_zone(self.address.addressable.time_zone).change(year: st.year, month: st.month, day: st.day, hour: st.hour, min: st.min, sec: st.sec)
      end_time = DateTime.new.in_time_zone(self.address.addressable.time_zone).change(year: et.year, month: et.month, day: et.day, hour: et.hour, min: et.min, sec: et.sec)
      self.update_columns(start_time: start_time)
      self.update_columns(end_time: end_time)
    end
  end

  def end_time_is_after_start_time
    return if end_time.blank? || start_time.blank?
    if end_time < start_time
      errors.add(:end_time, "cannot be before the start time")
    # elsif end_time.in_time_zone(self.address.addressable.time_zone).strftime('%H:%M') == '00:00' && start_time.in_time_zone(self.address.addressable.time_zone).strftime('%H:%M') == '00:00' && !closed
    elsif end_time.in_time_zone(self.time_zone).strftime('%H:%M') == '00:00' && start_time.in_time_zone(self.time_zone).strftime('%H:%M') == '00:00' && !closed
      errors.add(:start_time, "must be greater than zero")
      errors.add(:end_time, "must be greater than zero")
    end
  end

end
