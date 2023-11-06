class CreateOrderfields < ActiveRecord::Migration[5.1]
  def change
    create_table :orderfields do |t|
      t.references :order, index: true, foreign_key: true
      t.references :company, index: true, foreign_key: true
      t.references :field, index: true, foreign_key: true
      t.references :fieldoption, index: true, foreign_key: true
      t.integer :field_type, default: 0
      t.string :value
      t.timestamps
    end
  end
end
