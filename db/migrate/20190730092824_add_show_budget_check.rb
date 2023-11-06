class AddShowBudgetCheck < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :show_remaining_budget, :integer, default: 1
  end
end
