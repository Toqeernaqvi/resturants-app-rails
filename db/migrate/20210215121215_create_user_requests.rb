class CreateUserRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :user_requests do |t|
      t.belongs_to :company, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.boolean :responded, default: false

      t.timestamps
    end
  end
end
