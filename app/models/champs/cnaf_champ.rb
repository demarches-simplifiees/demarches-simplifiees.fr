# frozen_string_literal: true

class Champs::CnafChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/cnaf-input-validation.middleware.ts

  validates :numero_allocataire, format: { with: /\A\d{1,7}\z/ }, if: -> { code_postal.present? && validate_champ_value? }
  validates :code_postal, format: { with: /\A\w{5}\z/ }, if: -> { numero_allocataire.present? && validate_champ_value? }

  store_accessor :value_json, :numero_allocataire, :code_postal

  def uses_external_data?
    true
  end

  def fetch_external_data
    return unless valid_champ_value?

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

  def numero_allocataire_input_id
    "#{input_id}-numero_alocataire"
  end

  def code_postal_input_id
    "#{input_id}-code_postal"
  end

  def focusable_input_id
    numero_allocataire_input_id
  end
end
