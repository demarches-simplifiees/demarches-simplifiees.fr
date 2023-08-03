class API::V2::BaseController < ApplicationController
  # Disable forgery protection for API controllers when the request is authenticated
  # with a bearer token. Otherwise the session will be nullified and we'll lose curent_user
  protect_from_forgery with: :null_session, unless: :token?
  skip_before_action :setup_tracking
  prepend_before_action :authenticate_administrateur_from_token

  private

  def context
    if api_token.present?
      api_token.context
    # web interface (/graphql) give current_administrateur
    elsif current_administrateur.present?
      {
        administrateur_id: current_administrateur.id,
        procedure_ids: current_administrateur.procedure_ids,
        write_access: true
      }
    end
  end

  def token?
    authorization_bearer_token.present?
  end

  def authenticate_administrateur_from_token
    if api_token.present?
      @current_user = api_token.administrateur.user
    end
  end

  def api_token
    if @api_token.nil?
      @api_token = APIToken
        .authenticate(authorization_bearer_token)
        &.tap { _1.touch(:last_v2_authenticated_at) } || false
    end
    @api_token
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
end
