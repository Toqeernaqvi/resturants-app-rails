class CreateBanAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :ban_addresses do |t|
      t.belongs_to :company, index: true, foreign_key: true
      t.belongs_to :address, index: true, foreign_key: true

      t.timestamps
    end
  end
end
