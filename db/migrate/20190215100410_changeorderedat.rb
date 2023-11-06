class Changeorderedat < ActiveRecord::Migration[5.1]
  def up
    change_column :orders, :ordered_at, :datetime
  end

  def down
    change_column :orders, :ordered_at, :date
  end
end
