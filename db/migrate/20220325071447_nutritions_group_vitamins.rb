class NutritionsGroupVitamins < ActiveRecord::Migration[5.1]
  def change
    if vitamin = Nutrition.find_or_create_by(name: 'Vitamin')
      nutritions = Nutrition.where("name ILIKE 'Vitamin %'")
      nutritions.update_all(parent_id: vitamin.id)
      Fooditem.joins(:nutritional_facts).distinct.each do |fooditem|
        fooditem.nutritional_facts.find_or_create_by(nutrition_id: vitamin.id)
      end
      Option.joins(:nutritional_facts).distinct.each do |option|
        option.nutritional_facts.find_or_create_by(nutrition_id: vitamin.id)
      end
    end
  end
end
