class AddDeletedCuisines < ActiveRecord::Migration[5.1]
  def change
    add_column :runningmenus, :deleted_cuisines, :string
  end
end
