class RemoveColumnFromAddresses < ActiveRecord::Migration[5.1]
  def change
    remove_column :addresses, :monday
    remove_column :addresses, :tuesday
    remove_column :addresses, :wednesday
    remove_column :addresses, :thursday
    remove_column :addresses, :friday
    remove_column :addresses, :saturday
    remove_column :addresses, :sunday
  end
end
