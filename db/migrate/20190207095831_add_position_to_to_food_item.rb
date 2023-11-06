class AddPositionToToFoodItem < ActiveRecord::Migration[5.1]
  def change
    add_column :gfooditems, :position, :integer
    add_column :goptionsets, :position, :integer
    add_column :gsections, :position, :integer
    add_column :fooditems, :position, :integer
    add_column :optionsets, :position, :integer
    add_column :sections, :position, :integer
    add_column :options, :position, :integer
    add_column :goptions, :position, :integer
  end
end
