class AddFooditemOptionsetsRelation < ActiveRecord::Migration[5.1]
  def change
    create_table :fooditems_optionsets, id: false do |t|
      t.references :fooditem, index: true, foreign_key: true
      t.references :optionset, index: true, foreign_key: true
    end
  end
end
