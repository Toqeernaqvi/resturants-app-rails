class AddBuffetFieldsToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :entree, :integer, default: 0
    add_column :companies, :appetizers, :integer, default: 0
    add_column :companies, :dessert, :integer, default: 0
    add_column :companies, :sides, :integer, default: 0
    add_column :companies, :buffet_per_user_budget, :decimal, :precision => 8, :scale => 4, default: 0
  end
end
