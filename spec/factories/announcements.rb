FactoryBot.define do
  factory :announcement do
    title "MyString"
    description "MyText"
    expiration "2021-02-18 11:15:22"
    admins false
    users false
    vendors false
  end
end
