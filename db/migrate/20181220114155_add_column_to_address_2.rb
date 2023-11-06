class AddColumnToAddress2 < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :monday_first_start_time, :time
    add_column :addresses, :tuesday_first_start_time, :time
    add_column :addresses, :wednesday_first_start_time, :time
    add_column :addresses, :thursday_first_start_time, :time
    add_column :addresses, :friday_first_start_time, :time
    add_column :addresses, :saturday_first_start_time, :time
    add_column :addresses, :sunday_first_start_time, :time
    add_column :addresses, :monday_first_end_time, :time
    add_column :addresses, :tuesday_first_end_time, :time
    add_column :addresses, :wednesday_first_end_time, :time
    add_column :addresses, :thursday_first_end_time, :time
    add_column :addresses, :friday_first_end_time, :time
    add_column :addresses, :saturday_first_end_time, :time
    add_column :addresses, :sunday_first_end_time, :time
    add_column :addresses, :monday_second_start_time, :time
    add_column :addresses, :tuesday_second_start_time, :time
    add_column :addresses, :wednesday_second_start_time, :time
    add_column :addresses, :thursday_second_start_time, :time
    add_column :addresses, :friday_second_start_time, :time
    add_column :addresses, :saturday_second_start_time, :time
    add_column :addresses, :sunday_second_start_time, :time
    add_column :addresses, :monday_second_end_time, :time
    add_column :addresses, :tuesday_second_end_time, :time
    add_column :addresses, :wednesday_second_end_time, :time
    add_column :addresses, :thursday_second_end_time, :time
    add_column :addresses, :friday_second_end_time, :time
    add_column :addresses, :saturday_second_end_time, :time
    add_column :addresses, :sunday_second_end_time, :time
  end
end
