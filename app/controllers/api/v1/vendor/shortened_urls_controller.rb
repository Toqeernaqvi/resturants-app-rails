class Api::V1::Vendor::ShortenedUrlsController < Api::V1::Vendor::ApiController
  def show
    token = ::Shortener::ShortenedUrl.extract_token(params[:id])
    track = Shortener.ignore_robots.blank? || request.human?
    url   = ::Shortener::ShortenedUrl.fetch_with_token(token: token, additional_params: params, track: track)
    render json: {url: url[:url], status: :moved_permanently}
  end
end