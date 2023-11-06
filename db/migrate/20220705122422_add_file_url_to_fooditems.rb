class AddFileUrlToFooditems < ActiveRecord::Migration[5.1]
  def change
    add_column :fooditems, :file_url, :string
  end
end
