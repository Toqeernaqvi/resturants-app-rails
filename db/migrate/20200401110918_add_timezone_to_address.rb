class AddTimezoneToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :time_zone, :string
  end
end
