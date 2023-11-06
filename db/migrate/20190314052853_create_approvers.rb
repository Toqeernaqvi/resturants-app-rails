class CreateApprovers < ActiveRecord::Migration[5.1]
  def change
    create_table :approvers do |t|
      t.references :billing, index: true, foreign_key: true
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
