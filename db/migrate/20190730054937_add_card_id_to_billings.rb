class AddCardIdToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :stripe_cc_id, :string, after: :customer_id
  end
end
