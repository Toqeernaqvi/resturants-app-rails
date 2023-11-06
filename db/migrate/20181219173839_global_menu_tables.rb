class GlobalMenuTables < ActiveRecord::Migration[5.1]
  def change
    create_table :gmenus do |t|
      t.references  :restaurant, index: true, foreign_key: true
      t.integer     :menu_type, default: 0, null: false
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :gsections do |t|
      t.references  :gmenu, index: true, foreign_key: true
      t.string      :name
      t.string      :description
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :gfooditems do |t|
      t.references  :gmenu, index: true, foreign_key: true
      t.string      :name
      t.string      :description
      t.integer     :price, default: 0, null: false
      t.integer     :calories, default: 0, null: false
      t.attachment  :gfooditems, :image, after: :calories

      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :dietaries_gfooditems, id: false do |t|
      t.references  :dietary, index: true, foreign_key: true
      t.references  :gfooditem, index: true, foreign_key: true
    end

    create_table :goptionsets do |t|
      t.references  :gmenu, index: true, foreign_key: true
      t.string      :name
      t.integer     :required, default: 0
      t.integer     :start_limit, default: 0, null: false
      t.integer     :end_limit, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps  null: false
    end

    create_table :goptions do |t|
      t.references  :goptionset, index: true, foreign_key: true
      t.string      :description
      t.integer     :price, default: 0, null: false
      t.integer     :calories, default: 0, null: false
      t.datetime    :deleted_at, index: true
      t.timestamps   null: false
    end
  end
end


# Restaurant.all.each do |r|
#   Gmenu.create!(restaurant_id: r.id, menu_type: 0)
# end