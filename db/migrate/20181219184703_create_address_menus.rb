class CreateAddressMenus < ActiveRecord::Migration[5.1]
  def change
    create_table :menus do |t|
      t.references  :address, index: true, foreign_key: true
      t.references  :gmenu, index: true, foreign_key: true
      t.integer     :menu_type, default: 0, null: false
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :sections do |t|
      t.references  :menu, index: true, foreign_key: true
      t.references  :gsection, index: true, foreign_key: true
      t.string      :name
      t.string      :description
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :fooditems do |t|
      t.references  :menu, index: true, foreign_key: true
      t.references  :gfooditem, index: true, foreign_key: true
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
      t.references  :goptionset, index: true, foreign_key: true
      t.string      :name
      t.integer     :required, default: 0
      t.integer     :start_limit, default: 0, null: false
      t.integer     :end_limit, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps  null: false
    end

    create_table :options do |t|
      t.references  :optionset, index: true, foreign_key: true
      t.references  :goption, index: true, foreign_key: true
      t.string      :description
      t.integer     :price, default: 0, null: false
      t.integer     :calories, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps   null: false
    end
  end
end
