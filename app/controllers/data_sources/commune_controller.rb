# frozen_string_literal: true

class DataSources::CommuneController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 1
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
    if postal_code?(params[:q])
      fetch_by_postal_code(params[:q])
    else
      fetch_by_name(params[:q])
    end
  end

  def fetch_by_name(name)
    Typhoeus.get("#{API_GEO_URL}/communes", params: {
      type: 'commune-actuelle,arrondissement-municipal',
      nom: name,
      boost: 'population',
      limit: 100
    }, timeout: 3)
  end

  def fetch_by_postal_code(postal_code)
    Typhoeus.get("#{API_GEO_URL}/communes", params: {
      type: 'commune-actuelle,arrondissement-municipal',
      codePostal: postal_code,
      boost: 'population',
      limit: 50
    }, timeout: 3)
  end

  def postal_code?(string)
    string.match?(/\A[-+]?\d+\z/) ? true : false
  end

  def format_results(results)
    results.reject(&method(:code_metropole?)).flat_map do |result|
      item = {
        name: result[:nom].tr("'", '’'),
        code: result[:code],
        epci_code: result[:codeEpci],
        departement_code: result[:codeDepartement]
      }.compact

      if result[:codesPostaux].present?
        result[:codesPostaux].map { item.merge(postal_code: _1) }
      else
        [item]
      end.map do |item|
        if params[:with_combined_code].present?
          {
            label: "#{item[:name]} (#{item[:postal_code]})",
            value: "#{item[:code]}-#{item[:postal_code]}"
          }
        else
          {
            label: "#{item[:name]} (#{item[:postal_code]})",
            value: item[:code],
            data: item[:postal_code]
          }
        end
      end
    end
  end

  def code_metropole?(result)
    result[:code].in?(['75056', '13055', '69123'])
  end
end
