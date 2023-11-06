class DietariesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :dietaries do |t|
      t.string :name
      t.text :description

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
