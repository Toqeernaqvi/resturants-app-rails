class DropOldMenus < ActiveRecord::Migration[5.1]
  def up
    Restaurant.all.each do |r|
      Gmenu.create!(restaurant_id: r.id, menu_type: 0)
    end

    drop_table :dietaries_fooditems
    drop_table :options
    drop_table :optionsets
    drop_table :fooditems
    drop_table :sections
    drop_table :menus
  end

  def down
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
      t.attachment  :fooditems, :image

      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :dietaries_fooditems, id: false do |t|
      t.references  :dietary, index: true, foreign_key: true
      t.references  :fooditem, index: true, foreign_key: true
    end

    create_table :optionsets do |t|
      t.references  :menu, index: true, foreign_key: true
      t.string      :name
      t.integer     :required, default: 0
      t.integer     :start_limit, default: 0, null: false
      t.integer     :end_limit, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps  null: false
    end

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
