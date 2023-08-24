class Dossiers::EditFooterComponent < ApplicationComponent
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

  def submit_draft_button_options
    {
      class: 'fr-btn fr-btn--sm',
      disabled: !owner?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit' }
    }
  end

  def submit_en_construction_button_options
    {
      class: 'fr-btn fr-btn--sm',
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit' },
      form: { id: "form-submit-en-construction" }
    }
  end

  def render?
    !@dossier.for_procedure_preview?
  end
end
