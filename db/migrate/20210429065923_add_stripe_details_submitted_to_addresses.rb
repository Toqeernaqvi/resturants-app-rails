class AddStripeDetailsSubmittedToAddresses < ActiveRecord::Migration[5.1]
  def change
  	add_column :addresses, :stripe_details_submitted, :boolean, default: false
  end
end
