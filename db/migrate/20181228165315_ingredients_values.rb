class IngredientsValues < ActiveRecord::Migration[5.1]
  def change
    Ingredient.create(name: 'Chicken')
    Ingredient.create(name: 'Beef')
    Ingredient.create(name: 'Lamb')
    Ingredient.create(name: 'Turkey')
    Ingredient.create(name: 'Fish')
    Ingredient.create(name: 'Seafood')
    Ingredient.create(name: 'Eggs')
    Ingredient.create(name: 'Pork')
  end
end
