class Addstatusestomodels < ActiveRecord::Migration[5.1]
  def change
    add_column :menus, :status, :integer, default: 0, after: :gmenu_id
    add_column :fooditems, :status, :integer, default: 0, after: :name
    add_column :sections, :status, :integer, default: 0, after: :name
    add_column :optionsets, :status, :integer, default: 0, after: :name
    add_column :options, :status, :integer, default: 0, after: :description

    add_column :menus, :parent_status, :integer, default: 0, after: :gmenu_id
    add_column :fooditems, :parent_status, :integer, default: 0, after: :name
    add_column :sections, :parent_status, :integer, default: 0, after: :name
    add_column :optionsets, :parent_status, :integer, default: 0, after: :name
    add_column :options, :parent_status, :integer, default: 0, after: :description

    add_column :gmenus, :status, :integer, default: 0, after: :id
    add_column :gfooditems, :status, :integer, default: 0, after: :name
    add_column :gsections, :status, :integer, default: 0, after: :name
    add_column :goptionsets, :status, :integer, default: 0, after: :name
    add_column :goptions, :status, :integer, default: 0, after: :description

    add_column :gmenus, :parent_status, :integer, default: 0, after: :id
    add_column :gfooditems, :parent_status, :integer, default: 0, after: :name
    add_column :gsections, :parent_status, :integer, default: 0, after: :name
    add_column :goptionsets, :parent_status, :integer, default: 0, after: :name
    add_column :goptions, :parent_status, :integer, default: 0, after: :description

    add_column :restaurants, :status, :integer, default: 0, after: :notes
    add_column :restaurants, :parent_status, :integer, default: 0, after: :notes
    add_column :cuisines, :status, :integer, default: 0, after: :description
    add_column :cuisines, :parent_status, :integer, default: 0, after: :description
    add_column :dietaries, :status, :integer, default: 0, after: :description
    add_column :dietaries, :parent_status, :integer, default: 0, after: :description
    add_column :ingredients, :status, :integer, default: 0, after: :description
    add_column :ingredients, :parent_status, :integer, default: 0, after: :description
    add_column :companies, :parent_status, :integer, default: 0, after: :status
    add_column :users, :parent_status, :integer, default: 0, after: :status
    add_column :addresses, :parent_status, :integer, default: 0, after: :status
  end
end
