class FooditemImageUrl < ActiveRecord::Migration[5.1]
  def change
    add_column :gfooditems, :old_image, :string, after: :image
  end
end
