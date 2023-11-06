class AddDeliveryInstructionsToAddresses < ActiveRecord::Migration[5.1]
  def change
  	add_column :addresses, :delivery_instructions, :text
  end
end
