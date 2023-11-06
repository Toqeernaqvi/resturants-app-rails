class AddRecurringDynamicSectionToAddressesRecurringSchedulers < ActiveRecord::Migration[5.1]
  def change
    add_reference :addresses_recurring_schedulers, :recurring_dynamic_section, index: false, foreign_key: true
  end
end
