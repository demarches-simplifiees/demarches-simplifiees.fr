class Champs::AddressChamp < Champs::TextChamp
  store_accessor :value_json, :not_in_ban
  store_accessor :data, :postal_code, :city_code, :country_code, :department_code, :region_code, :city_name, :street_address
  before_save :on_codes_change, if: :should_refresh_after_code_change?

  def full_address?
    data.present? && france?
  end

  def ban?
    not_in_ban != 'true'
  end

  def international?
    country_code.present? && country_code != 'FR'
  end

  def france?
    country_code == 'FR'
  end

  def country_code
    super.presence || 'FR'
  end

  def feature
    data.to_json if full_address?
  end

  def feature=(value)
    if value.blank?
      self.data = nil
    else
      feature = JSON.parse(value)
      if feature.key?('properties')
        self.data = APIGeoService.parse_ban_address(feature)
      else
        self.data = feature
      end
    end
  rescue JSON::ParserError
    self.data = nil
  end

  def address
    data.present? ? data : nil
  end

  def address_label
    data.present? ? data['label'] : value
  end

  def search_terms
    if data.present?
      [data['label'], data['department_name'], data['region_name'], data['city_name']]
    else
      [address_label]
    end
  end

  def to_s
    address_label.presence || ''
  end

  def for_tag
    address_label
  end

  def for_export
    value.present? ? address_label : nil
  end

  def for_api
    address_label
  end

  def code_departement
    if international?
      '99'
    else
      department_code
    end
  end

  def code_region
    region_code
  end

  def code_commune
    city_code
  end

  def code_postal
    postal_code
  end

  def code_postal=(value)
    self.postal_code = value
  end

  def code_pays
    country_code if international?
  end

  def code_postal?
    code_postal.present?
  end

  def code_commune?
    code_commune.present?
  end

  def code_departement?
    code_departement.present?
  end

  def departement_name
    if international? || code_departement?
      APIGeoService.departement_name(code_departement)
    end
  end

  def departement_code_and_name
    if international? || code_departement?
      "#{code_departement} – #{departement_name}"
    end
  end

  def departement
    if international? || code_departement?
      { code: code_departement, name: departement_name }
    end
  end

  def commune_name
    if international?
      city_name
    elsif code_departement? && code_postal? && code_commune?
      "#{APIGeoService.commune_name(code_departement, code_commune)} (#{code_postal})"
    end
  end

  def commune
    if code_commune? && code_postal?
      city_code = address.fetch('city_code')
      city_name = address.fetch('city_name')

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
      end.merge(postal_code: code_postal)
    end
  end

  def street_input_id
    "#{input_id}-street"
  end

  def commune_input_id
    "#{input_id}-commune"
  end

  def city_input_id
    "#{input_id}-city"
  end

  def departement_input_id
    "#{input_id}-departement"
  end

  def pays_input_id
    "#{input_id}-pays"
  end

  def code_postal_input_id
    "#{input_id}-code-postal"
  end

  private

  def communes
    if code_postal?
      APIGeoService.communes_by_postal_code(code_postal)
    else
      []
    end
  end

  def on_codes_change
    return if !code_commune?

    commune = communes.find { _1[:code] == code_commune }

    if commune.present?
      self.department_code = commune[:departement_code]
      self.region_code = commune[:region_code]
    else
      self.department_code = nil
      self.postal_code = nil
      self.city_code = nil
    end
  end

  def should_refresh_after_code_change?
    france? && (postal_code_changed? || city_code_changed?)
  end
end
