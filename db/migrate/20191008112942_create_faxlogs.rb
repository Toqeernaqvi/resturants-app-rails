class CreateFaxlogs < ActiveRecord::Migration[5.1]
  def change
    create_table :faxlogs do |t|
      t.string :from
      t.string :to
      t.string :media_url
      t.string :sid
      t.integer :status

      t.timestamps
    end
  end
end
