class CreateLineItems < ActiveRecord::Migration[5.1]
  def change
    create_table :line_items do |t|
    	t.references :invoice
    	t.integer :quantity
    	t.string :item
    	t.decimal :unit_price, :precision => 8, :scale => 2, default: 0
    	t.decimal :amount, :precision => 8, :scale => 2, default: 0
    	t.decimal :discount, :precision => 8, :scale => 2, default: 0
    	t.timestamps
    end
  end
end
