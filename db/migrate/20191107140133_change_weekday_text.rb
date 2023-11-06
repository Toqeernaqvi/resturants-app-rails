class ChangeWeekdayText < ActiveRecord::Migration[5.1]
  def change
    change_column :business_addresses, :weekday_text, :text
  end
end
