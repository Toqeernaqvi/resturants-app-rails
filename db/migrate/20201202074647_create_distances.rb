class CreateDistances < ActiveRecord::Migration[5.1]
  def change
    create_table :distances do |t|
      t.float :lat0
      t.float :long0
      t.float :lat1
      t.float :long1
      t.integer :unit, default: 0
      t.decimal :distance, precision: 8, scale: 2, default: 0.00
    end
  end
end
