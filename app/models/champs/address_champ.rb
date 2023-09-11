# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::AddressChamp < Champs::TextChamp
  def full_address?
    data.present?
  end

  def address
    full_address? ? data : nil
  end

  def address_label
    full_address? ? data['label'] : value
  end

  def search_terms
    if full_address?
      [data['label'], data['departement'], data['region'], data['city']]
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

  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIAddress::AddressAdapter.new(external_id).to_params
  end

  def departement_name
    APIGeoService.departement_name(address.fetch('department_code'))
  end

  def departement
    if full_address?
      { code: address.fetch('department_code'), name: departement_name }
    end
  end

  def commune
    if full_address?
      department_code = address.fetch('department_code')
      city_code = address.fetch('city_code')
      city_name = address.fetch('city_name')
      postal_code = address.fetch('postal_code')

      commune_name = APIGeoService.commune_name(department_code, city_code)
      commune_code = APIGeoService.commune_code(department_code, city_name)

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
