class AddRestaurantSettingsAttrsToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :individual_meals_cutoff, :integer, default: 22
    add_column :addresses, :buffet_cutoff, :integer, default: 48
  end
end
