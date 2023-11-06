class CreateNutritionalFacts < ActiveRecord::Migration[5.1]
  def change
    create_table :nutritional_facts do |t|
      t.belongs_to :nutrition
      t.belongs_to :factable, polymorphic: true
      t.decimal :value, precision: 8, scale: 2, default: 0.00
      t.timestamps
    end
  end
end
