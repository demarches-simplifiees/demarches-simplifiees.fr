class APIController < ApplicationController
  before_action :default_format_json
  before_action :authenticate_from_token

  private

  def default_format_json
    request.format = "json" if !request.params[:format]
  end

  def check_api_token
    if @api_token.nil?
      render json: {}, status: :unauthorized
    end
  end

  def authenticate_from_token
    @api_token = authenticate_with_http_token { |t, _o| APIToken.authenticate(t) }

    # legacy way of sending the token by url
    # not available in api v2
    if @api_token.nil?
      @api_token = APIToken.authenticate(params[:token])
    end

    if @api_token.present?
      @api_token.touch(:last_v1_authenticated_at)
      @current_user = @api_token.administrateur.user
    end
  end
end
