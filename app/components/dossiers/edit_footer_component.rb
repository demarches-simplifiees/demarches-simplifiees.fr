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
    @annotation
  end

  def button_options
    {
      class: 'fr-btn fr-btn--sm',
      disabled: !owner?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit' }
    }
  end

  def render?
    !@dossier.for_procedure_preview?
  end
end
