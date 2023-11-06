class AddErrorsInTempSchedules < ActiveRecord::Migration[5.1]
  def change
    add_column :temp_schedules, :validation_errors, :string
  end
end
