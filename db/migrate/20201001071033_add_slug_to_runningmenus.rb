class AddSlugToRunningmenus < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :slug, :string
    add_index :runningmenus, :slug, unique: true
  end
end
