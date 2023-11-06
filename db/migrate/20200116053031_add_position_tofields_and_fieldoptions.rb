class AddPositionTofieldsAndFieldoptions < ActiveRecord::Migration[5.1]
  def change
    add_column :fields, :position, :integer, index: true
    add_column :fieldoptions, :position, :integer, index: true
  end
end
