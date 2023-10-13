class DataSources::AdresseController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 3
      response = Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: params[:q], limit: 10 })
      result = JSON.parse(response.body, symbolize_names: true)
      render json: result[:features].map { { label: _1[:properties][:label], value: _1[:properties][:label] } }
    else
      render json: []
    end
  end
end
