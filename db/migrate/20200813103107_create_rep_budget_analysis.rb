class CreateRepBudgetAnalysis < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_budget_analyses do |t|
      t.references :company
      t.references :address
      t.string :company_name
      t.string :company_address
      t.bigint :quantity
      t.decimal :food_cost, default: 0, precision: 8, scale: 2
      t.decimal :food_cost_avg, default: 0, precision: 8, scale: 2
      t.decimal :service_cost_avg, default: 0, precision: 8, scale: 2
      t.decimal :budget, default: 0, precision: 8, scale: 2
      t.date :dated_on
      t.timestamps
    end
  end
end
