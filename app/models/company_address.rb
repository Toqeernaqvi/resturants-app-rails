class CompanyAddress < Address
  default_scope -> { where(addressable_type: 'Company') }
  # belongs_to :company, foreign_key: :addressable_id
end
