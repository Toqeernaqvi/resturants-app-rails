class AddHoursFieldsToRecurring < ActiveRecord::Migration[5.1]
  def change
    add_column :recurring_schedulers, :cutoff_hours, :integer, default: 22
    add_column :recurring_schedulers, :cutoff_minutes, :integer, default: 0
    add_column :recurring_schedulers, :admin_cutoff_hours, :integer, default: 22
    add_column :recurring_schedulers, :admin_cutoff_minutes, :integer, default: 0
    add_column :recurring_schedulers, :pickup_hours, :integer, default: 1
    add_column :recurring_schedulers, :pickup_minutes, :integer, default: 15
  end
end
