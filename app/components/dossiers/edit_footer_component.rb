# frozen_string_literal: true

class Dossiers::EditFooterComponent < ApplicationComponent
  delegate :can_passer_en_construction?, :can_transition_to_en_construction?, :user_buffer_changes?, to: :@dossier

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

  def can_submit?
    can_submit_draft? || can_submit_en_construction?
  end

  def can_submit_draft?
    !annotation? && can_transition_to_en_construction?
  end

  def can_submit_en_construction?
    owner? && user_buffer_changes?
  end

  def submit_button_label
    if can_submit_draft?
      t('.submit')
    else
      t('.submit_changes')
    end
  end

  def submit_button_path
    if can_submit_draft?
      brouillon_dossier_path(@dossier)
    elsif @dossier.editing_fork?
      modifier_dossier_path(@dossier.editing_fork_origin)
    else
      modifier_dossier_path(@dossier)
    end
  end

  def submit_button_options
    if can_submit_draft?
      submit_draft_button_options
    else
      submit_en_construction_button_options
    end
  end

  def disabled_submit_button_options
    {
      class: 'fr-text--sm fr-mb-0 fr-mr-2w',
      data: { 'fr-opened': "true" },
      aria: { controls: 'modal-eligibilite-rules-dialog' }
    }
  end

  def submit_draft_button_options
    {
      class: 'fr-btn',
      disabled: !owner? || !can_passer_en_construction?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit', turbo_force: :server }
    }
  end

  def submit_en_construction_button_options
    {
      class: 'fr-btn',
      disabled: !can_passer_en_construction?,
      method: :post,
      data: { 'disable-with': t('.submitting'), controller: 'autosave-submit', turbo_force: :server },
      form: { id: "form-submit-en-construction" }
    }
  end

  def render?
    !@dossier.for_procedure_preview?
  end
end
