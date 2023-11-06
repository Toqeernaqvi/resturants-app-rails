class AddAdjustableToAdjustments < ActiveRecord::Migration[5.1]
  def change
    add_reference :adjustments, :adjustable, polymorphic: true
    add_column :adjustments, :adjustment_type, :integer, default: 0
  end
end
