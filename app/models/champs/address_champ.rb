# frozen_string_literal: true

class Champs::AddressChamp < Champs::TextChamp
  def full_address?
    data.present?
  end

  def feature=(value)
    h = if value.blank?
      nil
    else
      feature = JSON.parse(value)
      if feature.key?('properties')
        APIGeoService.parse_ban_address(feature)
      else
        feature
      end
    end

    self.data = h
    self.value_json = h
  rescue JSON::ParserError
    self.data = nil
    self.value_json = nil
  end

  def selected_items
    if value.present?
      [{ value:, label: value, data: full_address? ? data : nil }]
    else
      []
    end
  end

  def address
    full_address? ? data : nil
  end

  def address_label
    full_address? ? data['label'] : value
  end

  def search_terms
    if full_address?
      [data['label'], data['department_name'], data['region_name'], data['city_name']]
    else
      [address_label]
    end
  end

  def code_departement
    if full_address?
      address.fetch('department_code')
    end
  end

  def code_region
    if full_address?
      address.fetch('region_code')
    end
  end

  def departement_name
    APIGeoService.departement_name(code_departement)
  end

  def departement_code_and_name
    if full_address?
      "#{code_departement} – #{departement_name}"
    end
  end

  def departement
    if full_address?
      { code: code_departement, name: departement_name }
    end
  end

  def commune_name
    return if !full_address?

    commune = APIGeoService.commune_name(code_departement, address['city_code'])

    return commune if address['postal_code'].blank?

    "#{commune} (#{address['postal_code']})"
  end

  def commune
    if full_address?
      city_code = address.fetch('city_code')
      city_name = address.fetch('city_name')
      postal_code = address.fetch('postal_code')

      commune_name = APIGeoService.commune_name(code_departement, city_code)
      commune_code = APIGeoService.commune_code(code_departement, city_name)

      if commune_name.present?
        {
          code: city_code,
          name: commune_name
        }
      elsif commune_code.present?
        {
          code: commune_code,
          name: city_name
        }
      else
        {
          code: city_code,
          name: city_name
        }
      end.merge(postal_code:)
    end
  end
end
