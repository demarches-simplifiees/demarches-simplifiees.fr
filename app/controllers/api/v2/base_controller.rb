class API::V2::BaseController < ApplicationController
  # Disable forgery protection for API controllers when the request is authenticated
  # with a bearer token. Otherwise the session will be nullified and we'll lose curent_user
  protect_from_forgery with: :null_session, unless: :token?
  skip_before_action :setup_tracking
  prepend_before_action :authenticate_administrateur_from_token

  private

  def context
    # new token give administrateur_id
    if api_token.administrateur?
      { administrateur_id: api_token.administrateur_id, token: api_token.token }
    # web interface (/graphql) give current_administrateur
    elsif current_administrateur.present?
      { administrateur_id: current_administrateur.id }
    # old token
    else
      { token: api_token.token }
    end
  end

  def token?
    authorization_bearer_token.present?
  end

  def authorization_bearer_token
    @authorization_bearer_token ||= begin
      received_token = nil
      authenticate_with_http_token do |token, _options|
        received_token = token
      end
      received_token
    end
  end

  def authenticate_administrateur_from_token
    if api_token.administrateur?
      administrateur = Administrateur.includes(:user).find_by(id: api_token.administrateur_id)
      if administrateur.valid_api_token?(api_token.token)
        @current_user = administrateur.user
      end
    end
  end

  def api_token
    @api_token ||= APIToken.new(authorization_bearer_token)
  end
end
