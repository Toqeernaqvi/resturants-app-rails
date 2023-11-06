class ChangeDefaultUserMarkup < ActiveRecord::Migration[5.1]
  def change
    change_column :orders, :user_markup, :boolean, default: false
  end
end
