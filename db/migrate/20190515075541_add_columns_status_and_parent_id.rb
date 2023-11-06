class AddColumnsStatusAndParentId < ActiveRecord::Migration[5.1]
  def change
    add_column :menus, :request_status, :integer, default: 0
    add_column :menus, :draft_id, :integer, :null => true

    add_column :restaurants, :request_status, :integer, default: 0
    add_column :restaurants, :draft_id, :integer, :null => true

    add_column :sections, :draft_id, :integer, :null => true
    add_column :fooditems, :draft_id, :integer, :null => true
    add_column :optionsets, :draft_id, :integer, :null => true
    add_column :options, :draft_id, :integer, :null => true
    add_column :dietaries, :draft_id, :integer, :null => true
    add_column :ingredients, :draft_id, :integer, :null => true
  end
end
