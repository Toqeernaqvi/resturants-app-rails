class AddAddress < ActiveRecord::Migration[5.1]
  def change
    add_reference :billings, :address, index: true
    add_reference :approvers, :address, index: true
  end
end
