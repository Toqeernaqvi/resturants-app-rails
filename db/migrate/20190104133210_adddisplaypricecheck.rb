class Adddisplaypricecheck < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :display_price, :integer, after: :name
  end
end
