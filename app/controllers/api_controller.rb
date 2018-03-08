class APIController < ApplicationController
  before_action :authenticate_user
  before_action :default_format_json

  def authenticate_user
    if !valid_token?
      request_http_token_authentication
    end
  end

  protected

  def valid_token?
    current_administrateur.present?
  end

  def current_administrateur
    @administrateur ||= (authenticate_with_bearer_token || authenticate_with_param_token)
  end

  def authenticate_with_bearer_token
    authenticate_with_http_token do |token, options|
      find_administrateur(token)
    end
  end

  def authenticate_with_param_token
    find_administrateur(params[:token])
  end

  def find_administrateur(token)
    Administrateur.find_by(api_token: token)
  end

  def default_format_json
    request.format = "json" if !request.params[:format]
  end
end
