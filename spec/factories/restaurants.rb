FactoryBot.define do

  factory :restaurant do
    sequence :name do |n|
      "Restaurant#{n + 30}"
    end
    migrated 1
    preferred_vendor false
  end
end