class IngredientsRelatedTables < ActiveRecord::Migration[5.1]
  def change
    add_column :gfooditems, :spicy, :integer, :default => 0, after: :calories
    add_column :gfooditems, :best_seller, :integer, :default => 0, after: :spicy
    
    add_column :fooditems, :spicy, :integer, :default => 0, after: :calories
    add_column :fooditems, :best_seller, :integer, :default => 0, after: :spicy

    create_table :gfooditems_ingredients, id: false do |t|
      t.references :gfooditem, index: true, foreign_key: true
      t.references :ingredient, index: true, foreign_key: true
    end

    create_table :fooditems_ingredients, id: false do |t|
      t.references :fooditem, index: true, foreign_key: true
      t.references :ingredient, index: true, foreign_key: true
    end

    create_table :dietaries_goptions, id: false do |t|
      t.references :dietary, index: true, foreign_key: true
      t.references :goption, index: true, foreign_key: true
    end

    create_table :dietaries_options, id: false do |t|
      t.references :dietary, index: true, foreign_key: true
      t.references :option, index: true, foreign_key: true
    end

    create_table :goptions_ingredients, id: false do |t|
      t.references :goption, index: true, foreign_key: true
      t.references :ingredient, index: true, foreign_key: true
    end

    create_table :ingredients_options, id: false do |t|
      t.references :ingredient, index: true, foreign_key: true
      t.references :option, index: true, foreign_key: true
    end
  end
end
