class AddNeutritionCheckToSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :settings, :display_nutritionix, :boolean, default: false
  end
end
