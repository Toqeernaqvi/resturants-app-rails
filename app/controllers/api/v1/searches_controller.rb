class Api::V1::SearchesController < Api::V1::ApiController
  before_action :get_address, only: [:restaurants]
  def index
    keyword = "*"
    if params[:keyword].present?
      keyword = params[:keyword]
    end
    suggestions = []
    if params[:keyword].present? && params[:keyword].downcase == "spicy"
      results = Searchkick.search("*", {load: false, where: {spicy: 1}, models: [Restaurant, Cuisine, Section, Fooditem, Dietary, Ingredient] })
    else
      results = Searchkick.search(keyword, {match: :word_start,load: false, models: [Restaurant, Cuisine, Section, Fooditem, Dietary, Ingredient] })
    end
    results.group_by{|res| [res.name, res.description, res.spicy, res["_index"]]}.keys.each do |title, description, spicy, type|
      class_name = type.split("_").first.singularize.titleize
      if params[:keyword] == 'spicy'
        obj = {'title': title, description: '', spicy: (spicy == 1 ? 'spicy' : ''), type: ''}
      elsif class_name == 'Section' && !title.include?(params[:keyword])
        obj = {'title': title, description: description, spicy: '', type: ''}
      else
        type = class_name
        if class_name == 'Fooditem'
          type = 'Item'
        elsif class_name == 'Dietary'
          type = 'Dietary Restriction'
        end
        obj = {'title': title, 'description': description, spicy: (spicy == 1 ? 'spicy' : ''), 'type': type}
      end
      suggestions << obj
    end
    render json: suggestions
  end

  def restaurants
    restaurants = []
    cuisines_arr = []
    dietaries = []
    ingredients = []
    cuisine_ids = params[:cuisine_ids]&.map(&:to_i) || []
    dietary_ids = params[:dietary_ids]&.map(&:to_i) || []
    ingredient_ids = params[:ingredient_ids]&.map(&:to_i) || []
    menu_type = params[:meal_type] == "buffet" ? params[:meal_type] : params[:menu_type]
    results = RestaurantAddress.query({keyword: params[:keyword], lat: @address.latitude, long: @address.longitude, time_zone: current_member.company.time_zone, delivery_at: params[:delivery_at], time: params[:delivery_at].to_time.strftime("%H:%M"), day: params[:delivery_at].to_time.strftime("%A").downcase, menu_type: menu_type, ban_ids: current_member.company.ban_addresses.pluck(:address_id), order_by: params[:order_by], order_type: params[:order_type], enable_self_service: @address.addressable.enable_saas })
    results.group_by{ |a| a.restaurant.id }.each do |restaurant_id, locations|
      res = locations.min {|a,b| distance([@address.latitude, @address.longitude], [a.location.coordinates[1], a.location.coordinates[0]]) <=> distance([@address.latitude, @address.longitude], [b.location.coordinates[1], b.location.coordinates[0]]) }
      cuisines = res.cuisines&.sort_by{|c| c.id}&.map{|c| c.name}.uniq
      cuisines = cuisines.blank? ? "" : cuisines.first(3).join(", ")
      restaurants << {_id: res.id, id: res.id, name: res.restaurant.name, holidays: res.holidays, status: res.status, discount_percentage: res.discount_percentage, rating_count: res.rating_count, average_rating: res.average_rating, enable_marketplace: res.enable_marketplace, enable_self_service: res.enable_self_service, individual_meals_cutoff: res.individual_meals_cutoff, buffet_cutoff: res.buffet_cutoff, avg_price: res.send("#{menu_type}_avg"), restaurant_status: res.restaurant.status, cuisines: cuisines, restaurant_cuisines: res.cuisines, dietaries: res.dietaries, ingredients: res.ingredients, location: res.location, images: (res.random_menu_images ? RestaurantAddress.random_images(res.id, menu_type) : res.images).compact }
      cuisines_arr << res.cuisines
      dietaries << res.dietaries
      ingredients << res.ingredients
    end
    dietaries = dietaries&.flatten&.uniq
    ingredients = ingredients&.flatten&.uniq
    cuisines = cuisines_arr&.flatten&.uniq
    dietaries.map{ |d| dietary_ids.include?(d["id"]) ? d["selected"] = true : d["selected"] = false }
    ingredients.map{ |i| ingredient_ids.include?(i["id"]) ? i["selected"] = true : i["selected"] = false }
    cuisines.map{ |c| cuisine_ids.include?(c["id"]) ? c["selected"] = true : c["selected"] = false }
    render json: { order_by: params[:order_by], order_type: params[:order_type], dietaries: dietaries, ingredients: ingredients, cuisines: cuisines, restaurants: restaurants }
  end

  def distance loc1, loc2
    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c # Delta in meters
  end

  private

  def get_address
    @address = current_member.company.addresses.find_by_id params[:address_id]
    if @address.blank?
      error(406, 'Company does not have this address')
    end
  end

end