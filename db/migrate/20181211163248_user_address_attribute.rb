class UserAddressAttribute < ActiveRecord::Migration[5.1]
  def change
    add_reference :users, :address, index: true, foreign_key: true, after: :office_admin_id

    # remove_column :contacts, :addresses_id, :integer, :default => 0
    add_reference :contacts, :address, index: true, foreign_key: true, after: :id
    rename_column :days_operations, :monay, :monday

    add_column :addresses, :lunch_order_capacity, :integer, default: 0, null: false
    add_column :addresses, :dinner_order_capacity, :integer, default: 0, null: false
    add_column :addresses, :monday, :string
    add_column :addresses, :tuesday, :string
    add_column :addresses, :wednesday, :string
    add_column :addresses, :thursday, :string
    add_column :addresses, :friday, :string
    add_column :addresses, :saturday, :string
    add_column :addresses, :sunday, :string
    add_column :addresses, :notes, :text
  end
end
