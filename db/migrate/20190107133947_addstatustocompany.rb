class Addstatustocompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :status, :integer, default: 0, after: :id
  end
end
