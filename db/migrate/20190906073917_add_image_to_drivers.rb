class AddImageToDrivers < ActiveRecord::Migration[5.1]
  def change
    add_column :drivers, :image, :string
  end
end
