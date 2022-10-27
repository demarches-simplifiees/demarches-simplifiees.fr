class Dossiers::EditFooterComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end

  private

  def owner?
    controller.current_user.owns?(@dossier)
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
