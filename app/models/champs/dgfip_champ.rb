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
class Champs::DgfipChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/dgfip-input-validation.middleware.ts
  validates :numero_fiscal, format: { with: /\A\w{13,14}\z/ }, if: -> { reference_avis.present? && validation_context != :brouillon }
  validates :reference_avis, format: { with: /\A\w{13,14}\z/ }, if: -> { numero_fiscal.present? && validation_context != :brouillon }

  store_accessor :value_json, :numero_fiscal, :reference_avis

  def blank?
    external_id.nil?
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    if valid?
      APIParticulier::DgfipAdapter.new(
        procedure.api_particulier_token,
        numero_fiscal,
        reference_avis,
        procedure.api_particulier_sources
      ).to_params
    end
  end

  def external_id
    if numero_fiscal.present? && reference_avis.present?
      { reference_avis: reference_avis, numero_fiscal: numero_fiscal }.to_json
    end
  end
end
