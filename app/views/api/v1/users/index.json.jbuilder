json.set! 'sorting_details' do
  json.sort_order @sort_order
  json.sort_type @sort_type
  json.total_count @count
  json.per_page @per_page
end
json.users @users
json.company_tags ActsAsTaggableOn::Tag.for_tenant(current_member.company_id).order(id: :asc).uniq
json.company_addresses current_member.company.addresses.collect{ |address| {id: address.id, address_line: address.address_line} }
json.time_zones ActiveSupport::TimeZone::MAPPING.collect {|t| {name:t[0],time_zone: t[1]}}
json.user_types User.user_types.select{|k| !k.in? ["admin", "restaurant_admin","operations","developer"]}
# json.set! 'users' do
#   json.array! @users do |user|
#     json.user do
#       json.id user.id
#       json.name user.name
#       json.email user.email
#       json.last_sign_in user.last_sign_in_at
#       json.active user.confirmed?
#     end
#   end
# end