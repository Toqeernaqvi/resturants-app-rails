class IngredientsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :ingredients do |t|
      t.string :name
      t.text :description

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
