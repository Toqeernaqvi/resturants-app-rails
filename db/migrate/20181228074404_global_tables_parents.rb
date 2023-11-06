class GlobalTablesParents < ActiveRecord::Migration[5.1]
  def change
    add_column :gmenus, :parent_id, :integer, after: :id
    add_index :gmenus, :parent_id

    add_column :gsections, :parent_id, :integer, after: :id
    add_index :gsections, :parent_id

    add_column :gfooditems, :parent_id, :integer, after: :id
    add_index :gfooditems, :parent_id

    add_column :goptionsets, :parent_id, :integer, after: :id
    add_index :goptionsets, :parent_id

    add_column :goptions, :parent_id, :integer, after: :id
    add_index :goptions, :parent_id

    add_column :menus, :parent_id, :integer, after: :id
    add_index :menus, :parent_id

    add_column :sections, :parent_id, :integer, after: :id
    add_index :sections, :parent_id

    add_column :fooditems, :parent_id, :integer, after: :id
    add_index :fooditems, :parent_id

    add_column :optionsets, :parent_id, :integer, after: :id
    add_index :optionsets, :parent_id

    add_column :options, :parent_id, :integer, after: :id
    add_index :options, :parent_id
  end
end
