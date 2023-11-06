class AddReviewCountToBusinessAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :business_addresses, :review_count, :integer, :default => 0
  end
end
