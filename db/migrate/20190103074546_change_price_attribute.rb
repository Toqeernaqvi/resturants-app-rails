class ChangePriceAttribute < ActiveRecord::Migration[5.1]
  def change
    remove_column :fooditems, :price, :integer
    remove_column :options, :price, :integer
    remove_column :gfooditems, :price, :integer
    remove_column :goptions, :price, :integer

    add_column :fooditems, :price, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :options, :price, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :gfooditems, :price, :decimal, default: 0, :precision => 8, :scale => 2
    add_column :goptions, :price, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
