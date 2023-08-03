class API::V2::BaseController < ApplicationController
  # Disable forgery protection for API controllers when the request is authenticated
  # with a bearer token. Otherwise the session will be nullified and we'll lose curent_user
  skip_forgery_protection if: -> { request.headers.key?('HTTP_AUTHORIZATION') }
  skip_before_action :setup_tracking
  before_action :authenticate_from_token

  private

  def context
    if @api_token.present?
      @api_token.context
    # web interface (/graphql) give current_administrateur
    elsif current_administrateur.present?
      {
        administrateur_id: current_administrateur.id,
        procedure_ids: current_administrateur.procedure_ids,
        write_access: true
      }
    end
  end

  private

  def authenticate_from_token
    @api_token = authenticate_with_http_token { |t, _o| APIToken.authenticate(t) }

    if @api_token.present?
      @api_token.touch(:last_v2_authenticated_at)
      @current_user = @api_token.administrateur.user
    end
  end
end
