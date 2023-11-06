class AddSequencesToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses, :lunch_sequence
    add_reference :addresses, :dinner_sequence
    add_reference :addresses, :breakfast_sequence
    add_reference :addresses, :buffet_sequence
  end
end
