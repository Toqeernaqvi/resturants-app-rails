class CreateRepCharts < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_charts do |t|
      t.references :company
      t.references :address
      t.decimal :expense, precision: 8, scale: 2, default: 0
      t.decimal :saving, precision: 8, scale: 2, default: 0
      t.bigint :meals
      t.date :dated_on
      t.timestamps
    end
  end
end
