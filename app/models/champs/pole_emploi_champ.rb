# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer          not null
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer          not null
#
class Champs::PoleEmploiChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/pole-emploi-input-validation.middleware.ts
  store_accessor :value_json, :identifiant

  def blank?
    external_id.nil?
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    return if !valid?

    APIParticulier::PoleEmploiAdapter.new(
      procedure.api_particulier_token,
      identifiant,
      procedure.api_particulier_sources
    ).to_params
  end

  def external_id
    { identifiant: identifiant }.to_json if identifiant.present?
  end
end
