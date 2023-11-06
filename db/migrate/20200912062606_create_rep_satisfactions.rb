class CreateRepSatisfactions < ActiveRecord::Migration[5.1]
  def change
    create_table :rep_satisfactions do |t|
      t.string :name
      t.references :dietary
      t.references :company
      t.references :address
      t.date :dated_on
      t.timestamps
    end
  end
end
