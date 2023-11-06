class PopulateRestaurantLocationShiftsData < ActiveRecord::Migration[5.1]
  def change
    RestaurantAddress.all.each do |a|
      a.monday_shifts.new(start_time: a.monday_first_start_time, end_time: a.monday_first_end_time) if a.monday_first_start_time.present? && a.monday_first_end_time.present?
      a.tuesday_shifts.new(start_time: a.tuesday_first_start_time, end_time:  a.tuesday_first_end_time) if a.tuesday_first_start_time.present? && a.tuesday_first_end_time.present?
      a.wednesday_shifts.new(start_time: a.wednesday_first_start_time, end_time:  a.wednesday_first_end_time) if a.wednesday_first_start_time.present? && a.wednesday_first_end_time.present?
      a.thursday_shifts.new(start_time: a.thursday_first_start_time, end_time:  a.thursday_first_end_time) if a.thursday_first_start_time.present? && a.thursday_first_end_time.present?
      a.friday_shifts.new(start_time: a.friday_first_start_time, end_time:  a.friday_first_end_time) if a.friday_first_start_time.present? && a.friday_first_end_time.present?
      a.saturday_shifts.new(start_time: a.saturday_first_start_time, end_time:  a.saturday_first_end_time) if a.saturday_first_start_time.present? && a.saturday_first_end_time.present?
      a.sunday_shifts.new(start_time: a.sunday_first_start_time, end_time:  a.sunday_first_end_time) if a.sunday_first_start_time.present? && a.sunday_first_end_time.present?

      a.monday_shifts.new(start_time: a.monday_second_start_time, end_time: a.monday_second_end_time) if a.monday_second_start_time.present? && a.monday_second_end_time.present?
      a.tuesday_shifts.new(start_time: a.tuesday_second_start_time, end_time:  a.tuesday_second_end_time) if a.tuesday_second_start_time.present? && a.tuesday_second_end_time.present?
      a.wednesday_shifts.new(start_time: a.wednesday_second_start_time, end_time:  a.wednesday_second_end_time) if a.wednesday_second_start_time.present? && a.wednesday_second_end_time.present?
      a.thursday_shifts.new(start_time: a.thursday_second_start_time, end_time:  a.thursday_second_end_time) if a.thursday_second_start_time.present? && a.thursday_second_end_time.present?
      a.friday_shifts.new(start_time: a.friday_second_start_time, end_time:  a.friday_second_end_time) if a.friday_second_start_time.present? && a.friday_second_end_time.present?
      a.saturday_shifts.new(start_time: a.saturday_second_start_time, end_time:  a.saturday_second_end_time) if a.saturday_second_start_time.present? && a.saturday_second_end_time.present?
      a.sunday_shifts.new(start_time: a.sunday_second_start_time, end_time:  a.sunday_second_end_time) if a.sunday_second_start_time.present? && a.sunday_second_end_time.present?
      a.save
    end
  end
end
