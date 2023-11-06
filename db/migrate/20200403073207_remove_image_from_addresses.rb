class RemoveImageFromAddresses < ActiveRecord::Migration[5.1]
  def change
    remove_column :addresses, :image, :string
  end
end
