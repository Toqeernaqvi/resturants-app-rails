class AddSequenceToCompanies < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses, :sequence
  end
end
