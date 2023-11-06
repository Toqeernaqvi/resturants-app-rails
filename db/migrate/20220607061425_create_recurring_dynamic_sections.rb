class CreateRecurringDynamicSections < ActiveRecord::Migration[5.1]
  def change
    create_table :recurring_dynamic_sections do |t|
      t.references :recurring_scheduler, foreign_key: true
      t.string :name
      t.string :icon, default: 'fas fa-heart'
      t.timestamps
    end
  end
end
