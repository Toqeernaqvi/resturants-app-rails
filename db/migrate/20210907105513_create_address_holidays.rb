class CreateAddressHolidays < ActiveRecord::Migration[5.1]
  def change
    create_table :holidays do |t|
      t.references :address
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
