class AddDriverSection < ActiveRecord::Migration[5.1]
  def change
    create_table :drivers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.integer :status, default: 0
      t.string :worker_id
      t.timestamps
    end
    add_reference :runningmenus, :driver, index: true, foreign_key: true
  end
end
