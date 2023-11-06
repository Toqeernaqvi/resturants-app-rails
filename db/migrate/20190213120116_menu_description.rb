class MenuDescription < ActiveRecord::Migration[5.1]
  def change
    change_column :sections, :description, :text, :limit => 4294967295
  end
end
