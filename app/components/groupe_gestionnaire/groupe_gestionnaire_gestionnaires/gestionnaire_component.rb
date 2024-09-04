# frozen_string_literal: true

class GroupeGestionnaire::GroupeGestionnaireGestionnaires::GestionnaireComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, gestionnaire:, is_gestionnaire: true)
    @groupe_gestionnaire = groupe_gestionnaire
    @gestionnaire = gestionnaire
    @is_gestionnaire = is_gestionnaire
  end

  def email
    if @gestionnaire == current_gestionnaire
      "#{@gestionnaire.email} (C’est vous !)"
    else
      @gestionnaire.email
    end
  end

  def created_at
    try_format_datetime(@gestionnaire.created_at)
  end

  def registration_state
    @gestionnaire.registration_state
  end

  def remove_button
    if is_there_at_least_another_active_admin? && @is_gestionnaire
      button_to 'Retirer du groupe',
       gestionnaire_groupe_gestionnaire_gestionnaire_path(@groupe_gestionnaire, @gestionnaire),
       method: :delete,
       class: 'fr-btn fr-btn--sm fr-btn--tertiary',
       form: { data: { turbo: true, turbo_confirm: "Retirer « #{@gestionnaire.email} » des gestionnaires de « #{@groupe_gestionnaire.name} » ?" } }
    end
  end

  def is_there_at_least_another_active_admin?
    if @gestionnaire.active?
      @groupe_gestionnaire.gestionnaires.count(&:active?) > 1
    else
      @groupe_gestionnaire.gestionnaires.count(&:active?) >= 1
    end
  end
end
