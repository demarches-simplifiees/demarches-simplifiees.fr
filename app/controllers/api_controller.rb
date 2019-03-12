class APIController < ApplicationController
  before_action :default_format_json

  protected

  def find_administrateur_for_token(procedure)
    procedure.administrateurs.find do |administrateur|
      administrateur.valid_api_token?(token)
    end
  end

  private

  def default_format_json
    request.format = "json" if !request.params[:format]
  end

  def token
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
