class MenuTables1 < ActiveRecord::Migration[5.1]
  def change
    add_attachment :fooditems, :image, after: :calories

    create_table :dietaries_fooditems, id: false do |t|
      t.references  :dietary, index: true, foreign_key: true
      t.references  :fooditem, index: true, foreign_key: true
    end
  end
end
