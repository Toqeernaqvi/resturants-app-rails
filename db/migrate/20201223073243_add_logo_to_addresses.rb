class AddLogoToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :logo, :string, limit: 510
  end
end
