FactoryBot.define do
  factory :company do
    name { Faker::Internet.name }
    image { ActionDispatch::Http::UploadedFile.new(:tempfile => File.new("#{Rails.root}/app/assets/images/logo.png"), :filename => "anyfile.png") }
  end
end