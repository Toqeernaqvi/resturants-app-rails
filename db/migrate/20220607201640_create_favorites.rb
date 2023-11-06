class CreateFavorites < ActiveRecord::Migration[5.1]
  def change
    create_table :favorites do |t|
      t.references :user, index: true, foreign_key: true
      t.references :company, index: true, foreign_key: true
      t.references :favoritable, polymorphic: true
    	t.timestamps
    end
    add_index :favorites, [:favoritable_id, :favoritable_type]
  end
end
