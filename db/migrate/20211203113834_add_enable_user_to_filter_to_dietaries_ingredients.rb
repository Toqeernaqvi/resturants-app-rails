class AddEnableUserToFilterToDietariesIngredients < ActiveRecord::Migration[5.1]
  def change
    add_column :dietaries, :enable_user_to_filter, :boolean, default: true
    add_column :ingredients, :enable_user_to_filter, :boolean, default: true
  end
end
