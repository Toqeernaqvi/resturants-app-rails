class AddIgnoreBudgetToFooditems < ActiveRecord::Migration[5.1]
  def change
    add_column :gfooditems, :ignore_budget, :boolean, default: false
    add_column :fooditems, :ignore_budget, :boolean, default: false
  end
end
