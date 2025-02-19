# frozen_string_literal: true

class Instructeurs::ScheduleRdvButtonComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end

  def call
    button_to instructeur_rdvs_path(@dossier.procedure, @dossier),
      data: { turbo: false },
      method: :post,
      class: 'fr-btn' do
      safe_join([
        t('.schedule_rdv'),
        content_tag(:span, nil, class: 'fr-ml-1w fr-icon-external-link-line', 'aria-hidden': 'true')
      ])
    end
  end
end
