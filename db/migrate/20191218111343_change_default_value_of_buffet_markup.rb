class ChangeDefaultValueOfBuffetMarkup < ActiveRecord::Migration[5.1]
  def self.up
    change_column_default :companies, :buffet_addons_markup, 30
    Company.where(buffet_addons_markup: 0).update_all(buffet_addons_markup: 30)
  end

  def self.down
    change_column_default :companies, :buffet_addons_markup, 0
  end
end
