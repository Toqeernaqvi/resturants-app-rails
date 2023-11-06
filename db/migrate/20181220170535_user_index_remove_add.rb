class UserIndexRemoveAdd < ActiveRecord::Migration[5.1]
  def up
    remove_index(:users, [:uid, :provider])
    add_index(:users, [:uid, :provider])
  end

  def down
    remove_index(:users, [:uid, :provider])
    add_index(:users, [:uid, :provider], unique: true)
  end
end
