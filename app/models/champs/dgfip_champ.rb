# frozen_string_literal: true

class Champs::DgfipChamp < Champs::TextChamp
  # see https://github.com/betagouv/api-particulier/blob/master/src/presentation/middlewares/dgfip-input-validation.middleware.ts
  validates :numero_fiscal, format: { with: /\A\w{13,14}\z/ }, if: -> { validate_champ_value? && reference_avis.present? }
  validates :reference_avis, format: { with: /\A\w{13,14}\z/ }, if: -> { validate_champ_value? && numero_fiscal.present? }

  store_accessor :value_json, :numero_fiscal, :reference_avis

  def fetch_external_data?
    true
  end

  def fetch_external_data
    return unless valid_champ_value?

    APIParticulier::DgfipAdapter.new(
      procedure.api_particulier_token,
      numero_fiscal,
      reference_avis,
      procedure.api_particulier_sources
    ).to_params
  end

  def external_id
    if numero_fiscal.present? && reference_avis.present?
      { reference_avis: reference_avis, numero_fiscal: numero_fiscal }.to_json
    end
  end

  def numero_fiscal_input_id
    "#{input_id}-numero_fiscal"
  end

  def reference_avis_input_id
    "#{input_id}-reference_avis"
  end

  def focusable_input_id
    numero_fiscal_input_id
  end
end
