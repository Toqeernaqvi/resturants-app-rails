class Addsettingtable < ActiveRecord::Migration[5.1]
  def change
    create_table :settings do |t|
      t.integer :minimum_amount, default: 0
      t.timestamps
    end
  end
end
