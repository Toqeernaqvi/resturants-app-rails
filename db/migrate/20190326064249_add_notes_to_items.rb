class AddNotesToItems < ActiveRecord::Migration[5.1]
  def change
  	add_column :fooditems, :notes_to_restaurant, :string
    add_column :gfooditems, :notes_to_restaurant, :string
  end
end
