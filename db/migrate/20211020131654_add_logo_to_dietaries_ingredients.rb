class AddLogoToDietariesIngredients < ActiveRecord::Migration[5.1]
  def self.up
    add_column :dietaries, :logo, :text
    add_column :dietaries, :alt_logo, :text
    add_column :ingredients, :logo, :text
    add_column :ingredients, :alt_logo, :text
  end
  def self.down
    remove_column :dietaries, :logo, :text
    remove_column :dietaries, :alt_logo, :text
    remove_column :ingredients, :logo, :text
    remove_column :ingredients, :alt_logo, :text
  end
end
