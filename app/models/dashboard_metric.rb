class DashboardMetric < ApplicationRecord
  enum metric_type: ["Highest Rated Restaurants", "Lowest Rated Restaurants", "Highest Rated Dishes & Their Restaurant Name", "Lowest Rated Dishes & Their Restaurant Name", "Restaurants Fall In Each Cuisine"]
  serialize :data, JSON

  def self.data_array(data)
    JSON.parse(JSON.parse(data))
  end

  def self.highest_rated_restaurants
    highest_rated_restaurants = RestaurantAddress.active.select("restaurants.id as restaurant_id, addresses.id as address_id, addressable_id, addressable_type, address_line, CONCAT (restaurants.name, ': ', addresses.address_line) restaurant_location, avg(rating_value) as rating_value, count(ratings.id) as rating_count").joins(:restaurant, :ratings).group('addresses.id, restaurants.id, restaurants.name, addresses.address_line').order('rating_value DESC').limit(10).map { |a| {restaurant_location: a.restaurant_location, rating_value: a.rating_value, restaurant_id: a.restaurant_id, address_id: a.address_id, rating_count: a.rating_count} }.to_json
    dmetric = DashboardMetric.find_by(metric_type: 0)
    if dmetric.blank?
      DashboardMetric.create(metric_type: 0, data: highest_rated_restaurants)
    else
      dmetric.update_attribute(:data, highest_rated_restaurants)
    end
  end

  def self.lowest_rated_restaurants
    lowest_rated_restaurants = RestaurantAddress.active.select("restaurants.id as restaurant_id, addresses.id as address_id, addressable_id, addressable_type, address_line, CONCAT (restaurants.name, ': ', addresses.address_line) restaurant_location, avg(rating_value) as rating_value, count(ratings.id) as rating_count").joins(:restaurant, :ratings).group('addresses.id, restaurants.id, restaurants.name, addresses.address_line').order('rating_value ASC').limit(10).map { |a| {restaurant_location: a.restaurant_location, rating_value: a.rating_value, restaurant_id: a.restaurant_id, address_id: a.address_id, rating_count: a.rating_count} }.to_json
    dmetric = DashboardMetric.find_by(metric_type: 1)
    if dmetric.blank?
      DashboardMetric.create(metric_type: 1, data: lowest_rated_restaurants)
    else
      dmetric.update_attribute(:data, lowest_rated_restaurants)
    end
  end

  def self.highest_rated_dishes
    highest_rated_dishes = Fooditem.active.select("restaurants.id as restaurant_id, addresses.id as address_id, fooditems.id as fooditem_id, fooditems.name as fooditem_name, CONCAT (restaurants.name, ': ', addresses.address_line) as restaurant_location, avg(ratings.rating_value) AS rating_value, count(ratings.id) as rating_count").joins(:ratings, menu: :address).joins("JOIN restaurants ON addresses.addressable_id = restaurants.id AND addresses.addressable_type = 'Restaurant'").group('fooditems.id, fooditems.name, restaurants.id, restaurants.name, addresses.id, addresses.address_line').order('rating_value DESC').limit(10).map{|f| {fooditem_name: f.fooditem_name, restaurant_location: f.restaurant_location, rating_value: f.rating_value, fooditem_id: f.fooditem_id, restaurant_id: f.restaurant_id, address_id: f.address_id, rating_count: f.rating_count} }.to_json
    dmetric = DashboardMetric.find_by(metric_type: 2)
    if dmetric.blank?
      DashboardMetric.create(metric_type: 2, data: highest_rated_dishes)
    else
      dmetric.update_attribute(:data, highest_rated_dishes)
    end
  end

  def self.lowest_rated_dishes
    lowest_rated_dishes = Fooditem.active.select("restaurants.id as restaurant_id, addresses.id as address_id, fooditems.id as fooditem_id, fooditems.name as fooditem_name, CONCAT (restaurants.name, ': ', addresses.address_line) as restaurant_location, avg(ratings.rating_value) AS rating_value, count(ratings.id) as rating_count").joins(:ratings, menu: :address).joins("JOIN restaurants ON addresses.addressable_id = restaurants.id AND addresses.addressable_type = 'Restaurant'").group('fooditems.id, fooditems.name, restaurants.id, restaurants.name, addresses.id, addresses.address_line').order('rating_value ASC').limit(10).map{|f| {fooditem_name: f.fooditem_name, restaurant_location: f.restaurant_location, rating_value: f.rating_value, fooditem_id: f.fooditem_id, restaurant_id: f.restaurant_id, address_id: f.address_id, rating_count: f.rating_count} }.to_json
    dmetric = DashboardMetric.find_by(metric_type: 3)
    if dmetric.blank?
      DashboardMetric.create(metric_type: 3, data: lowest_rated_dishes)
    else
      dmetric.update_attribute(:data, lowest_rated_dishes)
    end
  end

  def self.preferred_cuisines
    cuisines_data = Cuisine.active.all.uniq.map { |c| [c.name, CuisinesRestaurant.joins(:restaurant).where('cuisines_restaurants.cuisine_id = ? AND restaurants.status = ?', c.id, Restaurant.statuses[:active]).count]}
    x_values = cuisines_data.map(&:last)
    x_range = ((x_values.min)..(x_values.max)).to_a
    preferred_cuisines = [data: cuisines_data, x_range: x_range.last].to_json
    dmetric = DashboardMetric.find_by(metric_type: 4)
    if dmetric.blank?
      DashboardMetric.create(metric_type: 4, data: preferred_cuisines)
    else
      dmetric.update_attribute(:data, preferred_cuisines)
    end
  end
end
