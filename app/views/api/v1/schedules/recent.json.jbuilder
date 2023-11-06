json.set! 'orders' do
  json.array! @orders do |order|
    json.partial! "api/v1/orders/order", order: order
  end
end
