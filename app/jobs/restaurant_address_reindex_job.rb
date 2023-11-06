class RestaurantAddressReindexJob < ApplicationJob
  queue_as :restaurant_address_reindex

  def perform(id)
    RestaurantAddress.find(id).reindex
  end
end
