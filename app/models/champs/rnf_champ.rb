class Champs::RNFChamp < Champ
  store_accessor :data, :title, :email, :phone, :createdAt, :updatedAt, :dissolvedAt, :address, :status

  def rnf_id
    external_id&.gsub(/[[:space:]]/, '')
  end

  def value
    rnf_id
  end

  def fetch_external_data
    RNFService.new.(rnf_id:)
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  def blank?
    rnf_id.blank?
  end

  def code_departement
    address.present? && address['departmentCode']
  end

  def departement?
    code_departement.present?
  end

  def departement
    if departement?
      { code: code_departement, name: departement_name }
    end
  end

  def departement_name
    APIGeoService.departement_name(code_departement)
  end

  def departement_code_and_name
    if departement?
      "#{code_departement} – #{departement_name}"
    end
  end

  def commune_name
    if departement?
      "#{APIGeoService.commune_name(code_departement, address['cityCode'])} (#{address['postalCode']})"
    end
  end

  def commune
    if departement?
      city_code = address['cityCode']
      city_name = address['cityName']
      postal_code = address['postalCode']

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

  def rnf_address
    if departement?
      {
        label: address["label"],
        type: address["type"],
        street_address: address["streetAddress"],
        street_number: address["streetNumber"],
        street_name: address["streetName"],
        postal_code: address["postalCode"],
        city_name: address["cityName"],
        city_code: address["cityCode"],
        department_name: address["departmentName"],
        department_code: address["departmentCode"],
        region_name: address["regionName"],
        region_code: address["regionCode"]
      }.with_indifferent_access
    end
  end

  def full_address
    if address.present?
      address['label']
    end
  end
end
