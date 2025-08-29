# frozen_string_literal: true

class Champs::PoleEmploiChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/pole-emploi-input-validation.middleware.ts
  store :external_id, accessors: [:identifiant], coder: JSON

  def uses_external_data?
    true
  end

  def fetch_external_data
    APIParticulier::PoleEmploiAdapter.new(
      procedure.api_particulier_token,
      identifiant,
      procedure.api_particulier_sources
    ).to_params
  end
end
