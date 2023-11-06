class AddDishSizeToOrder < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :dishsize, foreign_key: true, after: :runningmenu_id
  end
end
