class Changesettingcolumn < ActiveRecord::Migration[5.1]
  def up
    change_column :settings, :minimum_amount, :decimal, default: 0, :precision => 8, :scale => 2
  end

  def down
    change_column :settings, :minimum_amount, :integer
  end
end
