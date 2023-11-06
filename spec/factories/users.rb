FactoryBot.define do
  factory :admin_user do
    email { Faker::Internet.email }
    password { "password"}
    confirmed_at { Date.today }
    user_type {User.user_types[:admin]}
  end
  
  factory :company_user do
    email { Faker::Internet.email }
    password { "password"}
    confirmed_at { Date.today }
    user_type {User.user_types[:company_user]}
    company { FactoryBot.create(:company) }
    office_admin { FactoryBot.create(:admin_user) }
  end
end