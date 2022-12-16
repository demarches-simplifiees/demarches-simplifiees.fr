# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean          default(FALSE)
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
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
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champs::CnafChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/cnaf-input-validation.middleware.ts
  validates :numero_allocataire, format: { with: /\A\d{1,7}\z/ }, if: -> { code_postal.present? && validation_context != :brouillon }
  validates :code_postal, format: { with: /\A\w{5}\z/ }, if: -> { numero_allocataire.present? && validation_context != :brouillon }

  store_accessor :value_json, :numero_allocataire, :code_postal

  def blank?
    external_id.nil?
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    if valid?
      APIParticulier::CnafAdapter.new(
        procedure.api_particulier_token,
        numero_allocataire,
        code_postal,
        procedure.api_particulier_sources
      ).to_params
    end
  end

  def external_id
    if numero_allocataire.present? && code_postal.present?
      { code_postal: code_postal, numero_allocataire: numero_allocataire }.to_json
    end
  end
end
