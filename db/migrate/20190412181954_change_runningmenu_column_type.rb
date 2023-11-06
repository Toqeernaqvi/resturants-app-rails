class ChangeRunningmenuColumnType < ActiveRecord::Migration[5.1]
  def change
    change_column :runningmenus, :per_meal_budget, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
