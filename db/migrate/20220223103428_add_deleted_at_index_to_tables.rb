class AddDeletedAtIndexToTables < ActiveRecord::Migration[5.1]
  def change
    add_index :addresses, :deleted_at
    add_index :companies, :deleted_at
    add_index :contacts, :deleted_at
    add_index :cuisines, :deleted_at
    add_index :dietaries, :deleted_at
    add_index :fields, :deleted_at
    add_index :fieldoptions, :deleted_at
    add_index :fooditems, :deleted_at
    add_index :gfooditems, :deleted_at
    add_index :gmenus, :deleted_at
    add_index :goptions, :deleted_at
    add_index :goptionsets, :deleted_at
    add_index :gsections, :deleted_at
    add_index :ingredients, :deleted_at
    add_index :menus, :deleted_at
    add_index :options, :deleted_at
    add_index :options_orders, :deleted_at
    add_index :optionsets, :deleted_at
    add_index :optionsets_orders, :deleted_at
    add_index :orders, :deleted_at
    add_index :restaurants, :deleted_at
    add_index :runningmenus, :deleted_at
    add_index :sections, :deleted_at
    add_index :users, :deleted_at
  end
end
