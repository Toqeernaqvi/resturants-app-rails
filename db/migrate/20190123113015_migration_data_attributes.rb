class MigrationDataAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :restaurants, :vendor_id, :integer, after: :notes
    add_column :restaurants, :migrated, :integer, default: 0, after: :vendor_id

    add_column :gfooditems, :item_id, :integer, after: :best_seller
  end
end
