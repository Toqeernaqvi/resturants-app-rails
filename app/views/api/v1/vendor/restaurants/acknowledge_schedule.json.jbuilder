json.array! @orders do |order|
  json.(order, :id, :quantity, :price, :total_price, :remarks, :orderrating, :rating_count, :average_rating, :ordered_at, :user_paid)
end