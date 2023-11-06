class AddTimingColumnsToDrivers < ActiveRecord::Migration[5.1]
  def change
    add_column :drivers, :monday_start_time, :datetime
    add_column :drivers, :tuesday_start_time, :datetime
    add_column :drivers, :wednesday_start_time, :datetime
    add_column :drivers, :thursday_start_time, :datetime
    add_column :drivers, :friday_start_time, :datetime
    add_column :drivers, :saturday_start_time, :datetime
    add_column :drivers, :sunday_start_time, :datetime
    add_column :drivers, :monday_end_time, :datetime
    add_column :drivers, :tuesday_end_time, :datetime
    add_column :drivers, :wednesday_end_time, :datetime
    add_column :drivers, :thursday_end_time, :datetime
    add_column :drivers, :friday_end_time, :datetime
    add_column :drivers, :saturday_end_time, :datetime
    add_column :drivers, :sunday_end_time, :datetime
    add_column :drivers, :car, :string
    add_column :drivers, :car_color, :string
    add_column :drivers, :car_licence_plate, :string
  end
end
