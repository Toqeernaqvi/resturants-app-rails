class AddMarketplaceToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :enable_marketplace, :boolean, default: :false
    add_column :addresses, :image, :string
  end
end
