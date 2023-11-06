class AddTimeBitsToSettings < ActiveRecord::Migration[5.1]
  def change
    add_column :settings, :breakfast, :boolean, default: false
    add_column :settings, :lunch, :boolean, default: false
    add_column :settings, :dinner, :boolean, default: false
  end
end