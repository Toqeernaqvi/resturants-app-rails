json.set! 'sorting_details' do
  json.sort_order @sort_order
  json.sort_type @sort_type
  json.total_count @count
  json.per_page @per_page
end
json.set! 'users' do
  json.array! @users do |user|
    json.user do
      json.id user.id
      json.name user.name
      json.user_type user.user_type
      json.email user.email
      json.last_sign_in user.last_sign_in_at
      json.active user.confirmed?
    end
  end
end