class AddDefaultToValidCard < ActiveRecord::Migration[5.1]
  def up
    change_column :users, :valid_card, :boolean, default: true
    change_column :share_meetings, :valid_card, :boolean, default: true
  end

  def down
    change_column :users, :valid_card, :boolean
    change_column :share_meetings, :valid_card, :boolean
  end
end
