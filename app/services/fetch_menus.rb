class FetchMenus < ApplicationService
  attr_accessor :current_member, :menus
  def initialize(user, menus)
    @current_member = user
    @menus = menus
  end

  def call
    items = []
    preferred_items = []
    menus_hash = JSON.parse(menus)
    dietaries = []
    ingredients = []

    sections = menus_hash["restaurants"].collect{|r| r["sections"] }
    fooditems = sections.flatten.compact.collect{|s| s["fooditems"] }
    fooditems.flatten.uniq.each do |fooditem|
      if current_member.present?
        member_dietaries = current_member.dietaries.uniq.pluck(:id)
        if fooditem["dietaries"].pluck("id").any?{|d| member_dietaries.include?(d) }
          fooditem["dietaries"].map{|d| member_dietaries.include?(d["id"]) ? d["checked"] = true : d["checked"] = false}
          fooditem["dietaries"].sort_by!{|a| a["checked"] ? 0 : 1 }
          preferred_items << fooditem
        end
      end
      items << fooditem
      dietaries << fooditem["dietaries"]
      ingredients << fooditem["ingredients"]
    end
    items = items.sort_by{|item| [ item["image"]["url"].blank? ? 0 : 1, item["average_rating"]&.to_f ] }.reverse
    preferred_items = preferred_items&.collect{|i| i if i["restaurant_name"] != ENV["BEV_AND_MORE"] }&.compact
    new_section = {name: "Based on Your Preferences", description: "We have selected the following dishes based on your dietary restrictions and preferences.", fooditems: preferred_items.take(15)}
    menus_hash["new_section"] = {}
    menus_hash["most_popular"] = {}
    if current_member.present?
      if current_member.dietaries.exists?
        menus_hash["new_section"] = preferred_items.blank? ? {} : new_section
      else
        menus_hash["new_section"]["dietaries"] = Dietary.active.select(:id, :name)
      end
      menus_hash["most_popular"] = popular_section(items)
    end

    dietaries = dietaries&.compact&.flatten&.select{|c| c["enable_user_to_filter"]}
    ingredients = ingredients&.compact&.flatten&.select{|c| c["enable_user_to_filter"]}
    menus_hash["dietaries"] = dietaries&.sort_by{|d| dietaries.count(d) }&.reverse&.uniq{|d| d["id"]}
    menus_hash["ingredients"] = ingredients&.sort_by{|i| ingredients.count(i) }&.reverse&.uniq{|d| d["id"]}
    menus_hash
  end

  def popular_section(items)
    #R = average for the item = (Rating) 4.14
    #v = number of votes for the item = (votes) 7
    #m = minimum votes required
    #C = global average of all items in the system
    #weighted rank (WR) = (v ÷ (v+m)) × R + (m ÷ (v+m)) × C
    return [] if items.blank?
    items = items.collect{|i| i if i["restaurant_name"] != ENV["BEV_AND_MORE"] }&.compact
    items = items.sort_by{|item| item["formula_value"] = (item["rating_count"].to_f) / ((item["rating_count"].to_f)+5) * (item["average_rating"].to_f)+(5/((item["rating_count"].to_f)+5)) * item["global_avg_rating"].to_f }.reverse&.take(10)
    items = items&.take(15)
  end
end