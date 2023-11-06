class CreateBusinessAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :business_addresses do |t|
      t.string :name
      t.decimal :rating, default: 0, :precision => 8, :scale => 2
      t.string :formatted_phone_number
      t.string :formatted_address
      t.string :vicinity
      t.integer :price_level, default: 0
      t.string :url
      t.string :website
      t.string :weekday_text
      t.string :business_type
      t.string :lat
      t.string :lng

      t.timestamps
    end
  end
end
