class Dsfr::CheckboxComponent < ApplicationComponent
  attr_reader :error

  def initialize(form:, target:, checkboxes:, error: nil)
    @form = form
    @target = target
    @checkboxes = checkboxes
    @error = error
  end

  def error?
    # TODO: mettre correctement le aria-labelled-by avec l'id du div qui contient les erreurs
    # https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bouton-radio/
    @error.present?
  end

  def each_checkboxes
    @checkboxes.each do |button|
      yield(*button.values_at(:label, :checked_value, :unchecked_value, :hint), button.except(:label, :checked_value, :unchecked_value, :hint))
    end
  end
end
