class RemoveColumnFromAddress2 < ActiveRecord::Migration[5.1]
  def change
  	remove_column :addresses, :monday_start_time, :datetime
    remove_column :addresses, :tuesday_start_time, :datetime
    remove_column :addresses, :wednesday_start_time, :datetime
    remove_column :addresses, :thursday_start_time, :datetime
    remove_column :addresses, :friday_start_time, :datetime
    remove_column :addresses, :saturday_start_time, :datetime
    remove_column :addresses, :sunday_start_time, :datetime
    remove_column :addresses, :monday_end_time, :datetime
    remove_column :addresses, :tuesday_end_time, :datetime
    remove_column :addresses, :wednesday_end_time, :datetime
    remove_column :addresses, :thursday_end_time, :datetime
    remove_column :addresses, :friday_end_time, :datetime
    remove_column :addresses, :saturday_end_time, :datetime
    remove_column :addresses, :sunday_end_time, :datetime
  end
end
