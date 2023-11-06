class Addnametoaddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :name, :string, after: :id, null: false
  end
end
