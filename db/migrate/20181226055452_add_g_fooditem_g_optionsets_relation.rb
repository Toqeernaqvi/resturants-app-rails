class AddGFooditemGOptionsetsRelation < ActiveRecord::Migration[5.1]
  def change
    create_table :gfooditems_goptionsets, id: false do |t|
      t.references :gfooditem, index: true, foreign_key: true
      t.references :goptionset, index: true, foreign_key: true
    end
  end
end
