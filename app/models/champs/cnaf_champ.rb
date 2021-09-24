# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::CnafChamp < Champs::TextChamp
  store_accessor :value_json, :numero_allocataire, :code_postal

  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIParticulier::CnafAdapter.new(
      procedure.api_particulier_token,
      numero_allocataire,
      code_postal,
      procedure.api_particulier_sources
    ).to_params
  end

  def external_id
    if numero_allocataire.present? && code_postal.present?
      { code_postal: code_postal, numero_allocataire: numero_allocataire }.to_json
    end
  end
end
