# frozen_string_literal: true

class Instructeurs::OCRViewerComponent < ApplicationComponent
  attr_reader :champ, :data

  def initialize(champ:)
    @champ, @data = champ, champ.data
  end

  def formated_data
    {
      titulaire: data.dig('rib', 'titulaire')&.join('<br>'),
      iban: data.dig('rib', 'iban'),
      bic: data.dig('rib', 'bic'),
      bank_name: data.dig('rib', 'bank_name')
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
