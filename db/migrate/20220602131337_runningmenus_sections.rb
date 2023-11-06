class RunningmenusSections < ActiveRecord::Migration[5.1]
  def change
    create_table :dynamic_sections do |t|
      t.references :runningmenu, index: true, foreign_key: true
      t.string :name
      t.timestamps
    end
  end
end
