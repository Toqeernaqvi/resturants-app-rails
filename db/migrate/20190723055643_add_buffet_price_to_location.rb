class AddBuffetPriceToLocation < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :buffet_price, :decimal, default: 0, :precision => 8, :scale => 2
  end
end
