class RestaurantsCuisinesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :cuisines_restaurants do |t|
      t.belongs_to :cuisine, index: true, foreign_key: true
      t.belongs_to :restaurant, index: true, foreign_key: true
    end
  end
end
