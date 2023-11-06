class AddChecksToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :attempts_count, :integer, default: 0
    add_column :users, :valid_card, :boolean, default: true
    add_column :share_meetings, :attempts_count, :integer, default: 0
    add_column :share_meetings, :valid_card, :boolean, default: true
  end
end
