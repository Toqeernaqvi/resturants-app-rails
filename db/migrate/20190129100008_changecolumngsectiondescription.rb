class Changecolumngsectiondescription < ActiveRecord::Migration[5.1]
  def up
    change_column :gsections, :description, :text, :limit => 4294967295
  end

  def down
    change_column :gsections, :description, :text, :limit => 4294967295
  end
end
