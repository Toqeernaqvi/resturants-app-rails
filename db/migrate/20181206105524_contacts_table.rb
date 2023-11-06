class ContactsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :contacts do |t|
      t.references :addresses, index: true, foreign_key: true
      t.string :name, null: false
      t.string :phone_number
      t.string :email
      t.string :fax

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
