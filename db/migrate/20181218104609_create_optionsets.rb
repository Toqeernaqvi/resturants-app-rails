class CreateOptionsets < ActiveRecord::Migration[5.1]
  def change
    create_table :optionsets do |t|
      t.references  :menu, index: true, foreign_key: true
      t.string      :name
      t.integer     :required, default: 0
      t.integer     :start_limit, default: 0, null: false
      t.integer     :end_limit, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps  null: false
    end
  end
end
