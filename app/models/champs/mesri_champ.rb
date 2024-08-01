# frozen_string_literal: true

class Champs::MesriChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/mesri-input-validation.middleware.ts
  store_accessor :value_json, :ine

  def blank?
    external_id.nil?
  end

  def fetch_external_data?
    true
  end

  def fetch_external_data
    return unless valid_champ_value?

    APIParticulier::MesriAdapter.new(
      procedure.api_particulier_token,
      ine,
      procedure.api_particulier_sources
    ).to_params
  end

  def external_id
    { ine: ine }.to_json if ine.present?
  end
end
