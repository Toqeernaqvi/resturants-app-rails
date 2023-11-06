class CreateDriverShifts < ActiveRecord::Migration[5.1]
  def change
    create_table :driver_shifts do |t|
      t.references :driver
      t.string :label
      t.datetime :start_time
      t.datetime :end_time
      t.timestamps
    end
  end
end
