class Removefooditemimagesattributes < ActiveRecord::Migration[5.1]
  def change
    remove_column :fooditems, :fooditems_file_name, :string
    remove_column :fooditems, :fooditems_content_type, :string
    remove_column :fooditems, :fooditems_file_size, :integer
    remove_column :fooditems, :fooditems_updated_at, :datetime

    remove_column :gfooditems, :gfooditems_file_name, :string
    remove_column :gfooditems, :gfooditems_content_type, :string
    remove_column :gfooditems, :gfooditems_file_size, :integer
    remove_column :gfooditems, :gfooditems_updated_at, :datetime
  end
end
