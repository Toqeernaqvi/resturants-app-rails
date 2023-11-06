module AuthenticationHelper
  def sign_in_as_a_valid_user
    @user ||= FactoryBot.create(:company_user)
    post '/api/v1/auth/sign_in', params:  { email: @user.email, password: "password"}.to_json, headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
  end
end