class APIController < ApplicationController
  before_action :default_format_json

  protected

  def find_administrateur_for_token(procedure)
    api_token = APIToken.find_and_verify(authorization_bearer_token)
    if api_token.present? && api_token.context.fetch(:procedure_ids).include?(procedure.id)
      api_token.touch(:last_v1_authenticated_at)
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
