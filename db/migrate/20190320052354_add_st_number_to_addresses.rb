class AddStNumberToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :street_number, :string, after: :formatted_address
  end
end
