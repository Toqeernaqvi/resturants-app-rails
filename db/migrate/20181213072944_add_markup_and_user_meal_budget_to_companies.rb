class AddMarkupAndUserMealBudgetToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :user_meal_budget, :integer, default: 0
    add_column :companies, :markup, :integer, default: 0
    add_column :companies, :company_package , :boolean, default: false
    add_column :companies, :reduced_markup, :integer , default:0
    add_column :companies, :reduced_markup_check , :boolean, default: false
  end
end
