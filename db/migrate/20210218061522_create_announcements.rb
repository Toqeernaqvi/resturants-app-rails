class CreateAnnouncements < ActiveRecord::Migration[5.1]
  def change
    create_table :announcements do |t|
      t.string :title
      t.text :description
      t.datetime :expiration
      t.integer :status, default: 0
      t.boolean :admins, default: true
      t.boolean :users, default: true
      t.boolean :vendors, default: true

      t.timestamps
    end
  end
end
