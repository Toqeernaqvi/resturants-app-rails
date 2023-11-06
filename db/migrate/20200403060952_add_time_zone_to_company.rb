class AddTimeZoneToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :time_zone, :string
  end
end
