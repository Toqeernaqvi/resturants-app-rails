class MenuTables < ActiveRecord::Migration[5.1]
  def change
    create_table :menus do |t|
      t.references  :menuable, polymorphic: true, index: true
      t.integer     :menu_type, default: 0, null: false
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :sections do |t|
      t.references  :menu, index: true, foreign_key: true
      t.string      :name
      t.string      :description
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :fooditems do |t|
      t.references  :menu, index: true, foreign_key: true
      t.string      :name
      t.string      :description
      t.integer     :price, default: 0, null: false
      t.integer     :calories, default: 0, null: false

      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end
  end
end


# section_id

# 1 restaurant    1   first
# 2               1   second
# 3               1   third
# 4               1   forth

# 5 address       1
# 6               2
# 7               3
# 8               4








