class AddTypeToCuisineslists < ActiveRecord::Migration[5.1]
  def change
    add_column :cuisineslists, :menu_type, :integer, default: 0
  end
end
