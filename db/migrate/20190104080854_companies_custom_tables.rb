class CompaniesCustomTables < ActiveRecord::Migration[5.1]
  def change
    create_table :fields do |t|
      t.references :company, index: true, foreign_key: true
      t.integer :field_type, default: 0
      t.string :name
      t.integer :required, default: 0

      t.datetime  :deleted_at, index: true
      t.timestamps
    end

    create_table :fieldoptions do |t|
      t.references :field, index: true, foreign_key: true
      t.string :name

      t.datetime  :deleted_at, index: true
      t.timestamps
    end
  end
end
