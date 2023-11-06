class Addstatustocompanyfields < ActiveRecord::Migration[5.1]
  def change
    add_column :fields, :status, :integer, default: 0
    add_column :fieldoptions, :status, :integer, default: 0
  end
end
