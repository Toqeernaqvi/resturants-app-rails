class AddressesRecurringScheduler < ApplicationRecord
  belongs_to :recurring_scheduler
  belongs_to :address
  belongs_to :recurring_dynamic_section, optional: true
end