class ChangeCompanyMarkupColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :companies, :markup, :decimal, precision: 8, :scale => 2, default: "0.0"
  end
end
