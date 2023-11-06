class AddSkipMarkupTogfooditem < ActiveRecord::Migration[5.1]
  def change
    add_column :fooditems, :skip_markup, :boolean, default: false
    add_column :gfooditems, :skip_markup, :boolean, default: false
  end
end
