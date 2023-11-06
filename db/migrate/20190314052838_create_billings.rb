class CreateBillings < ActiveRecord::Migration[5.1]
  def change
    create_table :billings do |t|
      t.references :company, index: true, foreign_key: true
      t.integer :invoice_credit_card
      t.string :name

      t.timestamps
    end
  end
end
