class CreateRepVendors < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_vendors do |t|
      t.references :company
      t.references :address
      t.references :restaurant
      t.string :name
      t.string :company_name
      t.string :cuisine
      t.decimal :rating, default: 0, precision: 8, scale: 2
      t.decimal :total_spent, default: 0, precision: 8, scale: 2
      t.decimal :number_of_meals, default: 0, precision: 8, scale: 2
      t.date :dated_on
      t.timestamps
    end
  end
end
