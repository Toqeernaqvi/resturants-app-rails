class AddRandomMenuImagesToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :random_menu_images, :boolean, default: false
  end
end
