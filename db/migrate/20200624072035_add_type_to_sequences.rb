class AddTypeToSequences < ActiveRecord::Migration[5.1]
  def change
    add_column :sequences, :menu_type, :integer, default: 0
  end
end
