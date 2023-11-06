class UsersDietaries < ActiveRecord::Migration[5.1]
  def change
    create_table :dietaries_users do |t|
      t.belongs_to :dietary, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
    end
  end
end
