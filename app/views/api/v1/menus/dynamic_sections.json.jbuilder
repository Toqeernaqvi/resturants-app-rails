# binding.pry
json.dynamic_sections @runningmenu.dynamic_sections.each do |dynamic_section|
  json.id dynamic_section.id
  json.name dynamic_section.name
  json.icon dynamic_section.icon
  json.fooditems Fooditem.active.joins(:tags).where(tags: { id: dynamic_section.tags.pluck(:id).uniq}) do |fooditem|
    json.partial! "api/v1/orders/fooditem", fooditem: fooditem
  end
end

json.favorites Fooditem.active.joins(favorites: :user).where("(favorites.company_id = #{current_member.company.id} AND users.user_type = #{User.user_types[:company_admin]}) OR (favorites.user_id = #{current_member.id} )").uniq.each do |favorite|
  json.partial! "api/v1/orders/fooditem", fooditem: favorite
end