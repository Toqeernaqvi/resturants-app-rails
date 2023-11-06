class ChangeRankColumnName < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses_runningmenus, :rank, :integer
  end
end
