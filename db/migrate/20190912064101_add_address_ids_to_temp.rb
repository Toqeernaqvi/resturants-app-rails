class AddAddressIdsToTemp < ActiveRecord::Migration[5.1]
  def change
    add_column :temp_schedules, :address_ids, :string
  end
end
