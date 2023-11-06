class RemoveSequenceFromAddresses < ActiveRecord::Migration[5.1]
  def change
    remove_reference :addresses, :sequence
  end
end
