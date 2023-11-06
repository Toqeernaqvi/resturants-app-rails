class CreateAllDriverShifts < ActiveRecord::Migration[5.1]
  def change
    create_table :all_driver_shifts do |t|
      Driver.all.each do |d|
        d.monday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.monday_shifts.blank?
        d.tuesday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.tuesday_shifts.blank?
        d.wednesday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.wednesday_shifts.blank?
        d.thursday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.thursday_shifts.blank?
        d.friday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.friday_shifts.blank?
        d.saturday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.saturday_shifts.blank?
        d.sunday_shifts.new(start_time: Time.current.beginning_of_day, end_time: Time.current.end_of_day) if d.sunday_shifts.blank?
        d.save
      end
    end
  end
end
