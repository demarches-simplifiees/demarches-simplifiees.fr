# frozen_string_literal: true

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
    return unless valid_champ_value?

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
