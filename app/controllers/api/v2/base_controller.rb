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

  def render_data(result)
    if result.to_h['errors'].blank?
      if block_given?
        render json: (yield result.data)
      else
        render json: result.data.to_h
      end
    else
      render_error(result)
    end
  end

  def render_error(result)
    errors = result.to_h['errors']
    extensions = errors.first['extensions']
    status = case extensions ? extensions[:code] : :error
    when :not_found
      404
    when :unauthorized
      401
    else
      400
    end
    render json: { errors: errors }, status: status
  end
end
