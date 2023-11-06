class CreateRepBoxes < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_boxes do |t|
      t.references :company
      t.references :address
      t.decimal :average_food_rating, precision: 8, scale: 2, default: 0
      t.decimal :average_service_rating, precision: 8, scale: 2, default: 0
      t.decimal :on_time_deliveries, default: 0
      t.bigint :meals, default: 0
      t.bigint :vendors, default: 0
      t.text :cuisines, array: true, default: []
      t.date :dated_on
      t.timestamps
    end
  end
end
