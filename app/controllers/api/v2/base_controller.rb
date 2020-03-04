class API::V2::BaseController < ApplicationController
  protect_from_forgery with: :null_session

  private

  def context
    {
      administrateur_id: administrateur_id,
      token: authorization_bearer_token
    }
  end

  def authorization_bearer_token
    received_token = nil
    authenticate_with_http_token do |token, _options|
      received_token = token
    end
    received_token
  end

  def administrateur_id
    if administrateur_signed_in?
      current_administrateur.id
    else
      JsonWebToken.decode(authorization_bearer_token)[:sub].to_i
    end
  rescue JWT::DecodeError
    nil
  end
end
