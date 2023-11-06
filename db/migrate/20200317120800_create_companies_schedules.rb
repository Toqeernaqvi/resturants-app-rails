class CreateCompaniesSchedules < ActiveRecord::Migration[5.1]
  def change
    create_table :companies_schedules do |t|
      t.references :address
      t.references :labels_seq
      t.references :cuisines_sequence
      t.references :addresses_cuisineslist
      t.date  :delivery_date

      t.timestamps
    end
  end
end
