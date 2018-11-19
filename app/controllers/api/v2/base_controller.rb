class API::V2::BaseController < ApplicationController
  protect_from_forgery with: :null_session

  private

  def context
    {
      administrateur_id: current_administrateur&.id,
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
end
