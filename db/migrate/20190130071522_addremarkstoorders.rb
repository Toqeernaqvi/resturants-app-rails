class Addremarkstoorders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :remarks, :string, after: :rating
  end
end
