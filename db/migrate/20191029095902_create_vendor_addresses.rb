class CreateVendorAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :addresses_vendors do |t|
      t.integer :user_id
      t.integer :address_id
    end
  end
end
