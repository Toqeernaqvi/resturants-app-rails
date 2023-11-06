class Api::V1::StripeController < Api::V1::Vendor::ApiController
  before_action :authenticate_member!

  # POST /stripe/connect
  # def connect
  #   begin
  #     response = HTTParty.post("https://connect.stripe.com/oauth/token",
  #       query: {
  #         client_secret: ENV["STRIPE_SECRET_KEY"],
  #         code: params[:code],
  #         grant_type: "authorization_code"
  #       }
  #     )
  #     if response.parsed_response.key?("error")
  #       error(E_INTERNAL, response.parsed_response["error_description"])
  #     else
  #       stripe_user_id = response.parsed_response["stripe_user_id"]
  #       current_member.update_attribute(:stripe_user_id, stripe_user_id)
  #       render json: {message: 'User successfully connected with Stripe!', user: current_member}
  #     end
  #   rescue *RecoverableExceptions => e
  #     error(E_INTERNAL, "Not connected with Stripe! #{e}")
  #   end
  # end

  def connect
    restaurant_address = RestaurantAddress.find params[:id]
    if restaurant_address.stripe_acc_id.nil?
      begin
        response = Stripe::Account.create({
          type: 'express',
          capabilities: {
            card_payments: {requested: true},
            transfers: {requested: true},
          },
          settings: {
            payouts: {
              schedule: {
                interval: 'manual',
              },
            },
          }
        })
        acc_id = response.id
        restaurant_address.update_columns(stripe_acc_id: acc_id)
        # return_url = "#{ENV["BACKEND_HOST"]}/admin/stripe_return/webhook?id=#{restaurant_address.id}"
        # refresh_url = "#{ENV["BACKEND_HOST"]}/admin/stripe_refresh/webhook?id=#{restaurant_address.id}"
        refresh_url = "#{ENV["VENDER_FRONTEND_HOST"]}/dashboard/restaurant/#{restaurant_address.id}/stripe_redirect"
        return_url = "#{ENV["VENDER_FRONTEND_HOST"]}/dashboard/restaurant/#{restaurant_address.id}/payments?connected=true"
        account_links = Stripe::AccountLink.create({
          account: acc_id,
          refresh_url: return_url,
          return_url: refresh_url,
          type: 'account_onboarding',
        })
        acc_link = account_links[:url]
        restaurant_address.update_columns(stripe_acc_link: acc_link)
        current_member.update_columns(stripe_admin: true)
        render json: {success: true, message: 'User successfully connected with Stripe!', link: acc_link}
      rescue => e
        render json: {success: false, message: e.message}, status: 406
      end
    else
      begin
        refresh_url = "#{ENV["VENDER_FRONTEND_HOST"]}/dashboard/restaurant/#{restaurant_address.id}/stripe_redirect"
        return_url = "#{ENV["VENDER_FRONTEND_HOST"]}/dashboard/restaurant/#{restaurant_address.id}/payments?connected=true"
        account_links = Stripe::AccountLink.create({
          account: restaurant_address.stripe_acc_id,
          refresh_url: return_url,
          return_url: refresh_url,
          type: 'account_onboarding',
        })
        acc_link = account_links[:url]
        restaurant_address.update_columns(stripe_acc_link: acc_link)
        current_member.update_columns(stripe_admin: true)
        render json: {success: true, message: 'User reconnected with Stripe!', link: acc_link}
      rescue => e
        render json: {success: false, message: e.message}, status: 406
      end
    end
  end

  def login
    restaurant_address = RestaurantAddress.find params[:id]
    if restaurant_address.stripe_acc_login.nil?
      begin
        link = Stripe::Account.create_login_link(restaurant_address.stripe_acc_id)
        login_link = link[:url]
        restaurant_address.update_columns(stripe_acc_login: login_link)
        render json: {success: true, message: 'User login link with Stripe!', link: login_link}
      rescue => e
        render json: {success: false, message: e.message}, status: 406
      end
    else
      render json: {success: true, message: 'User already have login link with Stripe', link: restaurant_address.stripe_acc_login}
    end
  end

  def completion
    restaurant_address = RestaurantAddress.find params[:id]
    acc_id = restaurant_address.stripe_acc_id
    details_submitted = restaurant_address.stripe_details_submitted
    if details_submitted || acc_id.nil?
      render json: {success: true, details_submitted: details_submitted}
    else
      begin
        account = Stripe::Account.retrieve(acc_id)
        details_submitted = account.details_submitted
        restaurant_address.update_columns(stripe_details_submitted: details_submitted)
        render json: {success: true, details_submitted: details_submitted}
      rescue => e
        render json: {success: false, message: e.message}, status: 406
      end
    end
  end

end