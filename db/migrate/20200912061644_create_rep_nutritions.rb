class CreateRepNutritions < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_nutritions do |t|
      t.string :name
      t.references :dietary
      t.references :company
      t.references :address
      t.references :user
      t.timestamps
    end
  end
end
