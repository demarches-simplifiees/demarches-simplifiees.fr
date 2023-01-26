class Dossiers::EditFooterComponent < ApplicationComponent
  def initialize(dossier:, annotation:)
    @dossier_for_editing = dossier
    @dossier = dossier.editing_fork? ? dossier.editing_fork_origin : dossier
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
      class: 'fr-btn fr-btn--sm fr-ml-2w',
      disabled: annotation? ? !@dossier_for_editing.forked_with_changes? : !owner?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit' }
    }
  end

  def reset_button_options
    {
      class: 'fr-btn fr-btn--sm fr-btn--tertiary',
      disabled: !@dossier_for_editing.forked_with_changes?,
      method: :delete,
      data: { 'disable-with': t('.submitting') }
    }
  end

  def render?
    !@dossier.for_procedure_preview?
  end
end
