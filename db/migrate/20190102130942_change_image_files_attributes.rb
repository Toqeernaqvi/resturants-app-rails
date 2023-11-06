class ChangeImageFilesAttributes < ActiveRecord::Migration[5.1]
  def change
    remove_column :fooditems, :image_file_name, :string
    remove_column :fooditems, :image_content_type, :string
    remove_column :fooditems, :image_file_size, :integer
    remove_column :fooditems, :image_updated_at, :datetime

    remove_column :gfooditems, :image_file_name, :string
    remove_column :gfooditems, :image_content_type, :string
    remove_column :gfooditems, :image_file_size, :integer
    remove_column :gfooditems, :image_updated_at, :datetime

    add_column :fooditems, :image , :string
    add_column :gfooditems, :image , :string
  end
end
