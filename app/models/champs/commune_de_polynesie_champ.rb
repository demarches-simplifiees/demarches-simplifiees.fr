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
class Champs::CommuneDePolynesieChamp < Champs::TextChamp
  def for_export
    if value.present? && (city_postal_code = APIGeo::API.commune_by_city_postal_code(value))
      [city_postal_code[:commune], city_postal_code[:code_postal].to_s, city_postal_code[:ile], city_postal_code[:archipel]]
    else
      ['', '', '', '']
    end
  end

  def self.options
    APIGeo::API.communes_de_polynesie
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
