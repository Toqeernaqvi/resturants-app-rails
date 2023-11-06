class PopulateNutritions < ActiveRecord::Migration[5.1]
  def self.up
    Nutrition.create(name: 'Calories')
    total_fat = Nutrition.create(name: 'Total Fat')
    Nutrition.create(name: 'Saturated Fat', parent_id: total_fat.id)
    Nutrition.create(name: 'Trans Fat', parent_id: total_fat.id)
    total_carbs = Nutrition.create(name: 'Total Carbs')
    Nutrition.create(name: 'Dietary Fiber', parent_id: total_carbs.id)
    Nutrition.create(name: 'Total Sugars', parent_id: total_carbs.id)
    Nutrition.create(name: 'Protein')
    Nutrition.create(name: 'Cholestrol')
    Nutrition.create(name: 'Sodium')
    Nutrition.create(name: 'Calcium')
    Nutrition.create(name: 'Iron')
    Nutrition.create(name: 'Potassium')
    Nutrition.create(name: 'Vitamin A')
    Nutrition.create(name: 'Vitamin B')
    Nutrition.create(name: 'Vitamin C')
    Nutrition.create(name: 'Vitamin D')
  end

  def self.down
    Nutrition.find_by_sql("TRUNCATE nutritions RESTART IDENTITY")
  end
end
