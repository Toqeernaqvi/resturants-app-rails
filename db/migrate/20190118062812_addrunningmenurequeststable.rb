class Addrunningmenurequeststable < ActiveRecord::Migration[5.1]
  def change
    create_table :runningmenu_requests do |t|
      t.integer     :runningmenu_request_type, null: false
      t.references  :company, index: true, foreign_key: true
      t.references  :address, index: true, foreign_key: true
      t.datetime    :delivery_at
      t.integer     :recurring, default: 0
      t.integer     :orders, default: 0
      t.integer     :monday, default: 0
      t.integer     :tuesday, default: 0
      t.integer     :wednesday, default: 0
      t.integer     :thursday, default: 0
      t.integer     :friday, default: 0
      t.integer     :status, default: 0
      t.datetime    :deleted_at, index: true

      t.timestamps null: false
    end
  end
end
