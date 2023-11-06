class RelatedItems < ActiveRecord::Migration[5.1]
  def change
    create_table :fooditems_sections, id: false do |t|
      t.references :section, index: true, foreign_key: true
      t.references :fooditem, index: true, foreign_key: true
    end
  end
end
