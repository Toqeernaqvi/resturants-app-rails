class CreateRatings < ActiveRecord::Migration[5.1]
  def change
    create_table :ratings do |t|
      t.integer :user_id
      t.string :comment
      t.integer :rating_value
      t.belongs_to :ratingable, polymorphic: true

      t.timestamps
    end
    add_index :ratings, [:ratingable_id, :ratingable_type]
  end
end
