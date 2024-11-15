# frozen_string_literal: true

class Champs::RNAChamp < Champ
  include RNAChampAssociationFetchableConcern

  validates :value, allow_blank: true, format: {
    with: /\AW[0-9A-Z]{9}\z/, message: I18n.t(:not_a_rna, scope: 'activerecord.errors.messages')
  }, if: :validate_champ_value_or_prefill?

  delegate :id, to: :procedure, prefix: true

  def title
    data&.dig("association_titre")
  end

  def update_with_external_data!(data:)
    update!(data:, value_json: extract_value_json(data:))
  end

  def identifier
    title.present? ? "#{value} (#{title})" : value
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def full_address
    address = data&.dig("adresse")
    return if address.blank?
    "#{address["numero_voie"]} #{address["type_voie"]} #{address["libelle_voie"]} #{address["code_postal"]} #{address["commune"]}"
  end

  def rna_address
    address = data&.dig("adresse")
    return if address.blank?
    {
      label: full_address,
      type: "housenumber",
      street_address: address["libelle_voie"] ? [address["numero_voie"], address["type_voie"], address["libelle_voie"]].compact.join(' ') : nil,
      street_number: address["numero_voie"],
      street_name: [address["type_voie"], address["libelle_voie"]].compact.join(' '),
      postal_code: address["code_postal"],
      city_name: address["commune"],
      city_code: address["code_insee"]
    }.with_indifferent_access
  end

  private

  def extract_value_json(data:)
    h = APIGeoService.parse_rna_address(data['adresse'])
    h.merge(title: data['association_titre'])
  end
end
