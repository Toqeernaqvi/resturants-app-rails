class RunningMenus < ActiveRecord::Migration[5.1]
  def change
    create_table :runningmenus do |t|
      t.integer     :runningmenu_type, default: 0, null: false
      t.references  :address, index: true, foreign_key: true
      t.datetime    :delivery_at
      t.datetime    :activation_at
      t.datetime    :cutoff_at
      t.datetime    :admin_cutoff_at
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end

    create_table :addresses_runningmenus, id: false do |t|
      t.references :address, index: true, foreign_key: true
      t.references :runningmenu, index: true, foreign_key: true
    end
  end
end
