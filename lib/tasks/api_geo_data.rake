# frozen_string_literal: true

namespace :api_geo_data do
  PATH = Rails.root.join('lib', 'data', 'api_geo')

  desc 'Refresh data from API Geo'
  task refresh: :environment do
    PATH.rmtree if PATH.exist?
    PATH.mkpath

    get_from_api_geo('regions', 'regions')
    departements = get_from_api_geo('departements?zone=metro,drom,com', 'departements')
    departements.each do |departement|
      departement_code = departement[:code]
      epci_filename = "epcis-#{departement_code}"
      if departement_code.start_with?('98')
        PATH.join("#{epci_filename}.json").write(JSON.dump([]))
      else
        get_from_api_geo("epcis?codeDepartement=#{departement_code}", epci_filename)
      end
      get_from_api_geo("communes?codeDepartement=#{departement_code}&type=commune-actuelle,arrondissement-municipal", "communes-#{departement_code}")
    end
  end

  def get_from_api_geo(query, filename)
    data = []
    PATH.join("#{filename}.json").open('w') do |f|
      response = Typhoeus.get("#{API_GEO_URL}/#{query}")
      json = JSON.parse(response.body).map(&:symbolize_keys).flat_map do |result|
        item = {
          name: result[:nom].tr("'", '’'),
          code: result[:code],
          epci_code: result[:codeEpci],
          departement_code: result[:codeDepartement],
          region_code: result[:codeRegion]
        }.compact

        if result[:codesPostaux].present?
          result[:codesPostaux].map { item.merge(postal_code: _1) }
        else
          [item]
        end
      end
      data = json
      f << JSON.pretty_generate(json.sort_by { _1[:code] })
    end
    data
  end
end
