class ChangeRatingColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :ratings, :comment, :text
  end
end
