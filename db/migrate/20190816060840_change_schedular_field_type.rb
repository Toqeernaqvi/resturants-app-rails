class ChangeSchedularFieldType < ActiveRecord::Migration[5.1]
  def up
    change_column :runningmenufields, :value, :text
  end
  def down
    change_column :runningmenufields, :value, :string
  end
end
