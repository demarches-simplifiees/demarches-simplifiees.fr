# frozen_string_literal: true

class Instructeurs::ScheduleRdvButtonComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end

  def call
    button_to instructeur_rdvs_path(@dossier.procedure, @dossier),
      data: { turbo: false },
      method: :post,
      form: { target: '_blank' },
      class: 'fr-btn' do
      safe_join([
        button_text,
        content_tag(:span, nil, class: 'fr-ml-1w fr-icon-external-link-line', 'aria-hidden': 'true')
      ])
    end
  end

  private

  def button_text
    if @dossier.last_booked_rdv.present?
      t('.schedule_another_rdv')
    else
      t('.schedule_rdv')
    end
  end
end
