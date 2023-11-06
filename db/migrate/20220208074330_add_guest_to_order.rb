class AddGuestToOrder < ActiveRecord::Migration[5.1]
  def change
    add_reference :orders, :guest, foreign_key: true, index: true
  end
end
