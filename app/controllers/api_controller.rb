class APIController < ApplicationController
  AUTHENTICATION_TOKEN_DESCRIPTION = <<-EOS
    L'authentification de l'API se fait via un header HTTP :

    ```
      Authorization: Bearer &lt;Token administrateur&gt;
    ```
  EOS

  # deny request with an empty token as we do not want it
  # to match the first admin with an empty token
  # it should not happen as an empty token is serialized by ''
  # and a administrateur without token has admin.api_token == nil
  before_action :ensure_token_is_present
  before_action :authenticate_user
  before_action :default_format_json

  def authenticate_user
    if !valid_token?
      request_http_token_authentication
    end
  end

  protected

  def valid_token?
    administrateur.present?
  end

  def administrateur
    @administrateur ||= (authenticate_with_bearer_token || authenticate_with_param_token)
  end

  def authenticate_with_bearer_token
    authenticate_with_http_token do |token, options|
      Administrateur.find_by(api_token: token)
    end
  end

  def authenticate_with_param_token
    Administrateur.find_by(api_token: params[:token])
  end

  def default_format_json
    request.format = "json" if !request.params[:format]
  end

  def ensure_token_is_present
    if params[:token].blank? && header_token.blank?
      render json: {}, status: 401
    end
  end

  def header_token
    received_token = nil
    authenticate_with_http_token do |token, _options|
      received_token = token
    end
    received_token
  end
end
