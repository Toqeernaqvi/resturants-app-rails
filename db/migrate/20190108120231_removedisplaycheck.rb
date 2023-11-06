class Removedisplaycheck < ActiveRecord::Migration[5.1]
  def change
    remove_column :companies, :display_price, :integer, after: :name
  end
end
