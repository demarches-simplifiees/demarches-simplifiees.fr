class DataSources::AdresseController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 3
      response = fetch_results

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        render json: format_results(results)
      else
        render json: []
      end
    else
      render json: []
    end
  end

  private

  def fetch_results
    Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: params[:q], limit: 10 })
  end

  def format_results(results)
    results[:features].map do
      {
        label: _1[:properties][:label],
        value: _1[:properties][:label],
        data: _1[:properties]
      }
    end
  end
end
