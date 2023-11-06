class RemoeTimingsFromDrivers < ActiveRecord::Migration[5.1]
  def change
    remove_column :drivers, :monday_start_time, :datetime
    remove_column :drivers, :tuesday_start_time, :datetime
    remove_column :drivers, :wednesday_start_time, :datetime
    remove_column :drivers, :thursday_start_time, :datetime
    remove_column :drivers, :friday_start_time, :datetime
    remove_column :drivers, :saturday_start_time, :datetime
    remove_column :drivers, :sunday_start_time, :datetime
    remove_column :drivers, :monday_end_time, :datetime
    remove_column :drivers, :tuesday_end_time, :datetime
    remove_column :drivers, :wednesday_end_time, :datetime
    remove_column :drivers, :thursday_end_time, :datetime
    remove_column :drivers, :friday_end_time, :datetime
    remove_column :drivers, :saturday_end_time, :datetime
    remove_column :drivers, :sunday_end_time, :datetime
  end
end
