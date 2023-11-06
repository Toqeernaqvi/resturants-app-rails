require "spec_helper"
describe "Stripe connect API", :type => :api do

  before :each do
    sign_in_as_a_valid_user
  end

  it "validate the stripe token" do
  	expect(last_response.status).to eq(200)
  end

end