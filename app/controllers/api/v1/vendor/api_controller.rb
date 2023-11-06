class Api::V1::Vendor::ApiController < Api::V1::ApiController
  devise_token_auth_group :member, contains: [:restaurant_admin]
end
