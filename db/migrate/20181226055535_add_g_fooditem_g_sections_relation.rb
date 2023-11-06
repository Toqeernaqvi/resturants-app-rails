class AddGFooditemGSectionsRelation < ActiveRecord::Migration[5.1]
  def change
    create_table :gfooditems_gsections, id: false do |t|
      t.references :gsection, index: true, foreign_key: true
      t.references :gfooditem, index: true, foreign_key: true
    end
  end
end
