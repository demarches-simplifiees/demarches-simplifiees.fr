# frozen_string_literal: true

class DataSources::AdresseController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 3
      response = fetch_results

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        return render json: format_results(results)
      end
    end

    render json: []

  rescue JSON::ParserError => e
    Sentry.set_extras(body: response.body, code: response.code)
    Sentry.capture_exception(e)
    render json: []
  end

  private

  def fetch_results
    Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: params[:q], limit: 10 }, timeout: 3)
  end

  def format_results(results)
    results[:features].flat_map do |feature|
      if feature[:properties][:type] == 'municipality'
        departement_code = feature[:properties][:context].split(',').first
        APIGeoService.commune_postal_codes(departement_code, feature[:properties][:citycode]).map do |postcode|
          feature.deep_merge(properties: { postcode:, label: "#{feature[:properties][:label]} (#{postcode})" })
        end
      else
        feature
      end
    end.map do
      {
        label: _1[:properties][:label],
        value: _1[:properties][:label],
        data: _1
      }
    end
  end
end
