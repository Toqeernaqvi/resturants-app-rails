class Addlonglattoaddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :longitude, :string, after: :zip
    add_column :addresses, :latitude, :string, after: :zip
  end
end
