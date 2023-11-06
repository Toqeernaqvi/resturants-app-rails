class SetRandomMenuImagesToRestaurants < ActiveRecord::Migration[5.1]
  def change    
    RestaurantAddress.active.where(enable_marketplace: true).update_all(random_menu_images: true)
  end
end
