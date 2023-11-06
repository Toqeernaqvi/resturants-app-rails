# app/controllers/api/v1/cuisines_controller.rb
class Api::V1::CuisinesController < Api::V1::ApiController

  #GET /cuisines
  def index
    @cuisines = Cuisine.active.all
  end

  def restaurants_cuisines
    @data = Restaurant.active.find_by_sql("SELECT restaurants.id as restaurant_id, restaurants.name as restaurant_name,
    (SELECT STRING_AGG(cuisines.name, '|') FROM cuisines
    INNER JOIN cuisines_restaurants as rc on rc.cuisine_id = cuisines.id
    INNER JOIN restaurants as r on r.id = rc.restaurant_id WHERE r.id = restaurants.id) as cuisines_name
    FROM restaurants
    group by restaurants.id, restaurants.name, cuisines_name")
  end
end
