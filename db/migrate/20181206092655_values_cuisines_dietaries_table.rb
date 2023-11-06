class ValuesCuisinesDietariesTable < ActiveRecord::Migration[5.1]
  def up
    Cuisine.create(name: 'Indian')
    Cuisine.create(name: 'American')
    Cuisine.create(name: 'Mexican')
    Cuisine.create(name: 'Mediterranean')
    Cuisine.create(name: 'Middle Eastern')
    Cuisine.create(name: 'Chinese')
    Cuisine.create(name: 'Japanese')
    Cuisine.create(name: 'Italian')
    Cuisine.create(name: 'Variety')


    Dietary.create(name: 'Vegan')
    Dietary.create(name: 'Low Carb')
    Dietary.create(name: 'Halal')
    Dietary.create(name: 'Gluten')
    Dietary.create(name: 'Shellfish')
    Dietary.create(name: 'Egg')
    Dietary.create(name: 'Nuts')
    Dietary.create(name: 'Soy')
    Dietary.create(name: 'Dairy')
    Dietary.create(name: 'Vegetarian')
    Dietary.create(name: 'Seafood')
  end

  def down
  end
end
