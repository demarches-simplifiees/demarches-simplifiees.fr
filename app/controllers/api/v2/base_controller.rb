class API::V2::BaseController < ApplicationController
  skip_forgery_protection if: -> { request.headers.key?('HTTP_AUTHORIZATION') }
  skip_before_action :setup_tracking
  before_action :authenticate_from_token
  before_action :ensure_authorized_network, if: -> { @api_token.present? }
  before_action :ensure_token_is_not_expired, if: -> { @api_token.present? }

  before_action do
    Current.browser = 'api'
  end

  private

  def context
    if @api_token.present?
      @api_token.context
    # web interface (/graphql) give current_administrateur
    elsif current_administrateur.present?
      graphql_web_interface_context
    else
      unauthenticated_request_context
    end
  end

  def graphql_web_interface_context
    {
      administrateur_id: current_administrateur.id,
      procedure_ids: current_administrateur.procedure_ids,
      write_access: true
    }
  end

  def unauthenticated_request_context
    {
      administrateur_id: nil,
      procedure_ids: [],
      write_access: false
    }
  end

  def authenticate_from_token
    @api_token = authenticate_with_http_token { |t, _o| APIToken.authenticate(t) }

    if @api_token.present?
      @api_token.touch(:last_v2_authenticated_at)
      @api_token.store_new_ip(request.remote_ip)
      @current_user = @api_token.administrateur.user
      Current.user = @current_user
    end
  end

  def ensure_authorized_network
    if @api_token.forbidden_network?(request.remote_ip)
      address = IPAddr.new(request.remote_ip)
      render json: { errors: ["request issued from a forbidden network. Add #{address.to_string}/#{address.prefix} to your allowed adresses in your /profil"] }, status: :forbidden
    end
  end

  def ensure_token_is_not_expired
    if @api_token.expired?
      render json: { errors: ['token expired'] }, status: :unauthorized
    end
  end
end
