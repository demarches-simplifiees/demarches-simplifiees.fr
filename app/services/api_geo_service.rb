class APIGeoService
  class << self
    def countries(locale: I18n.locale)
      I18nData.countries(locale)
        .merge(get_localized_additional_countries(locale))
        .map { |(code, name)| { name:, code: } }
        .sort_by { I18n.transliterate(_1[:name].tr('î', 'Î')) }
    end

    def country_name(code, locale: I18n.locale)
      countries(locale:).find { _1[:code] == code }&.dig(:name)
    end

    def country_code(name)
      return if name.nil?
      code = I18nData.country_code(name) || I18nData.country_code(name.humanize) || I18nData.country_code(name.titleize)
      if code.nil?
        countries_index_fr[I18n.transliterate(name).upcase]&.dig(:code)
      else
        code
      end
    end

    def regions
      get_from_api_geo(:regions).sort_by { I18n.transliterate(_1[:name]) }
    end

    def region_name(code)
      regions.find { _1[:code] == code }&.dig(:name)
    end

    def region_code(name)
      return if name.nil?
      regions.find { _1[:name] == name }&.dig(:code)
    end

    def departements
      [{ code: '99', name: 'Etranger' }] + get_from_api_geo('departements?zone=metro,drom,com').sort_by { _1[:code] }
    end

    def departement_name(code)
      departements.find { _1[:code] == code }&.dig(:name)
    end

    def departement_code(name)
      return if name.nil?
      departements.find { _1[:name] == name }&.dig(:code)
    end

    def epcis(departement_code)
      get_from_api_geo("epcis?codeDepartement=#{departement_code}").sort_by { I18n.transliterate(_1[:name]) }
    end

    def epci_name(departement_code, code)
      epcis(departement_code).find { _1[:code] == code }&.dig(:name)
    end

    def epci_code(departement_code, name)
      epcis(departement_code).find { _1[:name] == name }&.dig(:code)
    end

    def communes(departement_code)
      get_from_api_geo("communes?codeDepartement=#{departement_code}&type=commune-actuelle,arrondissement-municipal").sort_by { I18n.transliterate([_1[:name], _1[:postal_code]].join(' ')) }
    end

    def communes_by_postal_code(postal_code)
      if postal_code.size > 3
        metro_code = postal_code[0..1]
        drom_com_code = postal_code[0..2]
        if metro_code == '20'
          communes('2A') + communes('2B')
        elsif metro_code == '97' || metro_code == '98'
          departement_name(drom_com_code) ? communes(drom_com_code) : []
        else
          departement_name(metro_code) ? communes(metro_code) : []
        end
          .filter { _1[:postal_code] == postal_code }
          .sort_by { I18n.transliterate([_1[:name], _1[:postal_code]].join(' ')) }
      else
        []
      end
    end

    def commune_name(departement_code, code)
      communes(departement_code).find { _1[:code] == code }&.dig(:name)
    end

    def commune_code(departement_code, name)
      communes(departement_code).find { _1[:name] == name }&.dig(:code)
    end

    private

    def get_from_api_geo(scope)
      Rails.cache.fetch("api_geo_#{scope}", expires_in: 1.year) do
        response = Typhoeus.get("#{API_GEO_URL}/#{scope}")
        JSON.parse(response.body).map(&:symbolize_keys).flat_map do |result|
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
          end
        end
      end
    end

    def countries_index_fr
      Rails.cache.fetch('countries_index_fr', expires_in: 1.year) do
        countries(locale: 'FR').index_by { I18n.transliterate(_1[:name]).upcase }
      end
    end

    def get_localized_additional_countries(locale)
      additional_countries[locale.to_s.upcase] || {}
    end

    def additional_countries
      {
        'FR' => { 'XK' => 'Kosovo' },
        'EN' => { 'XK' => 'Kosovo' }
      }
    end
  end
end
