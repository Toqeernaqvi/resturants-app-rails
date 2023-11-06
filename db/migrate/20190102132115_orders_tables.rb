class OrdersTables < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.references :fooditem, index: true, foreign_key: true
      t.integer :quantity
      t.decimal :price, :precision => 8, :scale => 2, default: 0
      t.decimal :total_price, :precision => 8, :scale => 2, default: 0

      t.datetime  :deleted_at, index: true
      t.timestamps
    end

    create_table :optionsets_orders do |t|
      t.references :optionset, index: true, foreign_key: true
      t.references :order, index: true, foreign_key: true
      t.integer :required, default: 0

      t.datetime  :deleted_at, index: true
      t.timestamps
    end

    create_table :options_orders do |t|
      t.references :optionsets_order, index: true, foreign_key: true
      t.references :option, index: true, foreign_key: true
      t.decimal :price, :precision => 8, :scale => 2, default: 0

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
