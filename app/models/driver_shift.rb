class DriverShift < ApplicationRecord

  has_paper_trail versions: {
    scope: -> { order("id desc") }
  }

  attr_accessor :time_zone
  
  belongs_to :driver, optional: true
  validates :start_time, :end_time, presence: true
  before_validation :set_dates_as_utc, if: lambda { |ds| (!ds.new_record? && self.driver.updated_from_frontend.blank? && ds.driver.restaurant_address.present?) || (ds.new_record? && ds.time_zone.present?) }
  after_create :set_dates_as_utc_new, if: lambda { |ds| ds.driver.created_from_frontend.blank? && ds.driver.updated_from_frontend.blank? }

  validate :end_time_is_after_start_time

  def start_time_timezone
    time_zone = self.driver.restaurant_address.present? ? self.driver.restaurant_address.addressable.time_zone : 'US/Pacific'
    self.start_time.in_time_zone(time_zone)
  end

  def end_time_timezone
    time_zone = self.driver.restaurant_address.present? ? self.driver.restaurant_address.addressable.time_zone : 'US/Pacific'
    self.end_time.in_time_zone(time_zone)
  end

  def end_time_is_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time < start_time
      errors.add(:end_time, "cannot be before the start time") 
    end 
  end

  def set_dates_as_utc
    if self.start_time.present? && self.end_time.present?
      st = self.start_time
      et = self.end_time
      self.start_time = DateTime.new.in_time_zone(self.time_zone).change(year: st.year, month: st.month, day: st.day, hour: st.hour, min: st.min, sec: st.sec)
      self.end_time = DateTime.new.in_time_zone(self.time_zone).change(year: et.year, month: et.month, day: et.day, hour: et.hour, min: et.min, sec: et.sec)
    end
  end

  def set_dates_as_utc_new
    if self.driver.updated_from_frontend.blank? && self.start_time.present? && self.end_time.present? && self.time_zone.blank?
      st = self.start_time
      et = self.end_time
      start_time = DateTime.new.in_time_zone(self.driver.restaurant_address.addressable.time_zone).change(year: st.year, month: st.month, day: st.day, hour: st.hour, min: st.min, sec: st.sec)
      end_time = DateTime.new.in_time_zone(self.driver.restaurant_address.addressable.time_zone).change(year: et.year, month: et.month, day: et.day, hour: et.hour, min: et.min, sec: et.sec)
      self.update_columns(start_time: start_time)
      self.update_columns(end_time: end_time)
    end
  end

end
