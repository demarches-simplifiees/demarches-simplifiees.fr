class API::V2::BaseController < ApplicationController
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

  def render_demarche(result)
    render_data(result) do |data|
      { data: data.demarche.to_h }
    end
  end

  def render_dossier(result)
    render_data(result) do |data|
      { data: data.dossier.to_h }
    end
  end

  def render_data(result)
    if result.data.present?
      render json: (yield result.data)
    else
      render_error(result)
    end
  end

  def render_error(result)
    errors = result.to_h['errors']
    status = case errors.first['extensions'][:code]
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
