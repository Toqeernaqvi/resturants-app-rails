class AddIconToDynamicSections < ActiveRecord::Migration[5.1]
  def change
    add_column :dynamic_sections, :icon, :string, default: 'fas fa-heart'
  end
end
