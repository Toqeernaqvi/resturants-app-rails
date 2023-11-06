class BillAdjustmentTable < ActiveRecord::Migration[5.1]
  def change
    create_table :adjustments do |t|
    	t.references :restaurant_billing
      t.date :adjustment_date
    	t.text :description
    	t.decimal :price, :precision => 8, :scale => 2, default: 0
    	t.timestamps
    end
  end
end
