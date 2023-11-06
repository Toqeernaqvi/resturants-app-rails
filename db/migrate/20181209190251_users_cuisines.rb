class UsersCuisines < ActiveRecord::Migration[5.1]
  def change
    create_table :cuisines_users do |t|
      t.belongs_to :cuisine, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
    end
  end
end
