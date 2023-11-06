class AddIntercomDisplay < ActiveRecord::Migration[5.1]
  def change
    add_column :settings, :display_intercom, :boolean, default: false
  end
end
