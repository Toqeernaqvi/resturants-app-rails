class AddressesVendor < ApplicationRecord
  belongs_to :user
  belongs_to :address
end
