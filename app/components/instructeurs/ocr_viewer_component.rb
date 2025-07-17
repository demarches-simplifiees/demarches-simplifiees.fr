# frozen_string_literal: true

class Instructeurs::OCRViewerComponent < ApplicationComponent
  attr_reader :champ, :value_json

  def initialize(champ:)
    @champ, @value_json = champ, champ.value_json
  end

  def formated_data
    {
      titulaire: value_json.dig('rib', 'titulaire')&.join('<br>'),
      iban: value_json.dig('rib', 'iban'),
      bic: value_json.dig('rib', 'bic'),
      bank_name: value_json.dig('rib', 'bank_name')
    }
      .transform_values! { (it.presence || processing_error) }
  end

  def render?
    champ.RIB? && champ.external_data_fetched? && !champ.external_error_present?
  end

  private

  def processing_error
    tag.span class: 'fr-hint-text fr-text-default--warning font-weight-normal' do
      safe_join([
        dsfr_icon("fr-icon-warning-line", :sm, :mr),
        t('.processing_error')
      ])
    end
  end
end
