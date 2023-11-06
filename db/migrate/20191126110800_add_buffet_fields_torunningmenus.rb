class AddBuffetFieldsTorunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :entree, :integer, default: 0
    add_column :runningmenus, :appetizers, :integer, default: 0
    add_column :runningmenus, :dessert, :integer, default: 0
    add_column :runningmenus, :sides, :integer, default: 0
    add_column :runningmenus, :buffet_per_user_budget, :decimal, :precision => 8, :scale => 4, default: 0
  end
end
