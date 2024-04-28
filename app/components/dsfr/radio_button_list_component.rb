# frozen_string_literal: true

class Dsfr::RadioButtonListComponent < ApplicationComponent
  attr_reader :error

  def initialize(form:, target:, buttons:, error: nil)
    @form = form
    @target = target
    @buttons = buttons
    @error = error
  end

  def error?
    # TODO: mettre correctement le aria-labelled-by avec l'id du div qui contient les erreurs
    # https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bouton-radio/
    @error.present?
  end

  def each_button
    @buttons.each do |button|
      yield(*button.values_at(:label, :value, :hint), **button.except(:label, :value, :hint))
    end
  end
end
