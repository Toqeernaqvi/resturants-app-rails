class ChangeStatusDefault < ActiveRecord::Migration[5.1]
  def up
    change_column :runningmenus, :status, :integer, default: 1
  end

  def down
    change_column :runningmenus, :status, :integer, default: 0
  end
end
