require "rails_helper"
RSpec.describe Restaurant, :type => :model do
  
  before(:all) do
    @restaurant = build(:restaurant)
  end
  it "is valid with valid attributes" do
    expect(@restaurant).to be_valid
  end
  
end