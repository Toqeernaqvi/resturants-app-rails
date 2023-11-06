class Addsuitenumbertoaddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :suite_no, :string, after: :formatted_address
  end
end
