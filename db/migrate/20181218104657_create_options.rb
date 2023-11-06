class CreateOptions < ActiveRecord::Migration[5.1]
  def change
    create_table :options do |t|
      t.references  :optionset, index: true, foreign_key: true
      t.string      :description
      t.integer     :price, default: 0, null: false
      t.integer     :calories, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps   null: false
    end
  end
end
