class APIController < ApplicationController
  AUTHENTICATION_TOKEN_DESCRIPTION = <<-EOS
    L'authentification de l'API se fait via un header HTTP :

    ```
      Authorization: Bearer &lt;Token administrateur&gt;
    ```
  EOS

  before_action :default_format_json

  protected

  def valid_token_for_administrateur?(administrateur)
    administrateur.valid_api_token?(token)
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
