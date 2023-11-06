class ChangeCompanyBudgetType < ActiveRecord::Migration[5.1]
  def up
    change_column :companies, :user_meal_budget, :decimal, default: 0, :precision => 8, :scale => 2
  end

  def down
    change_column :companies, :user_meal_budget, :integer
  end
end
