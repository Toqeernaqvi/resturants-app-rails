require 'rails_helper'
include ActionController::RespondWith

# The authentication header looks something like this:
# {"access-token"=>"abcd1dMVlvW2BT67xIAS_A", "token-type"=>"Bearer", "client"=>"LSJEVZ7Pq6DX5LXvOWMq1w", "expiry"=>"1519086891", "uid"=>"darnell@konopelski.info"}

describe "Whether access is ocurring properly", type: :request do  
  before(:each) do
    @current_user = FactoryBot.create(:company_user)
  end 

  context "context: general authentication via API, " do
    it "should successfully login" do
      post api_v1_user_session_path, params:  { email: @current_user.email, password: "password"}.to_json, headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }               
      expect(response.status).to eq(200)
    end
  end
  
end