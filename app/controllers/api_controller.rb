class APIController < ApplicationController
  before_action :default_format_json

  protected

  def find_administrateur_for_token(procedure)
    api_token = APIToken.find_and_verify(authorization_bearer_token, procedure.administrateurs)
    if api_token.present? && procedure.administrateurs.include?(api_token.administrateur)
      api_token.administrateur
    end
  end

  private

  def default_format_json
    request.format = "json" if !request.params[:format]
  end

  def authorization_bearer_token
    params_token.presence || header_token
  end

  def header_token
    received_token = nil
    authenticate_with_http_token do |token, _options|
      received_token = token
    end
    received_token
  end

  def params_token
    params[:token]
  end
end
