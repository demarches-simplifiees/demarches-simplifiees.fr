class Dossiers::EditFooterComponent < ApplicationComponent
  delegate :can_passer_en_construction?, :ineligibilite_rules_computable?, to: :@dossier

  def initialize(dossier:, annotation:)
    @dossier = dossier
    @annotation = annotation
  end

  private

  def owner?
    controller.current_user.owns?(@dossier)
  end

  def annotation?
    @annotation.present?
  end

  def disabled_submit_buttons_options
    {
      class: 'fr-text--sm fr-mb-0 fr-mr-2w',
      data: { 'fr-opened': "true" },
      aria: { controls: 'modal-eligibilite-rules-dialog' }
    }
  end

  def submit_draft_button_options
    {
      class: 'fr-btn fr-btn--sm',
      disabled: !owner? || ineligibilite_rules_invalid?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit', turbo_force: :server }
    }
  end

  def submit_en_construction_button_options
    {
      class: 'fr-btn fr-btn--sm',
      disabled: ineligibilite_rules_invalid?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit', turbo_force: :server },
      form: { id: "form-submit-en-construction" }
    }
  end

  def ineligibilite_rules_invalid?
    ineligibilite_rules_computable? && !can_passer_en_construction?
  end

  def render?
    !@dossier.for_procedure_preview?
  end
end
