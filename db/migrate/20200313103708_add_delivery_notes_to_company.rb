class AddDeliveryNotesToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :delivery_notes, :text
  end
end
