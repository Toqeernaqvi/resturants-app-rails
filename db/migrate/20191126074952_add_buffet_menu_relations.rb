class AddBuffetMenuRelations < ActiveRecord::Migration[5.1]
  def change
    add_column :sections, :section_type, :integer, default: 0
    add_column :addresses, :add_contract_commission, :boolean, default: false
    add_column :addresses, :items_count, :integer, default: 0
    add_column :addresses, :minimum_discount_price, :decimal, precision: 8, scale: 4, default: 0
    add_column :addresses, :buffet_commission, :decimal, precision: 8, scale: 4, default: 0
    create_table :dishsizes do |t|
      t.belongs_to :address
      t.string :title
      t.text :description
      t.integer :serve_count, default: 0
      t.decimal :price, precision: 8, scale: 4, default: 0
      t.timestamps
    end

    create_table :dishsizes_fooditems, id: false do |t|
      t.references :fooditem, index: true, foreign_key: true
      t.references :dishsize, index: true, foreign_key: true
    end
  end
end
