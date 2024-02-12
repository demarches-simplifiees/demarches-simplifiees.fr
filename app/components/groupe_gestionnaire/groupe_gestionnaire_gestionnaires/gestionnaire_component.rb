class GroupeGestionnaire::GroupeGestionnaireGestionnaires::GestionnaireComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, gestionnaire:)
    @groupe_gestionnaire = groupe_gestionnaire
    @gestionnaire = gestionnaire
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
    if is_there_at_least_another_active_admin?
      button_to 'Retirer',
       gestionnaire_groupe_gestionnaire_gestionnaire_path(@groupe_gestionnaire, @gestionnaire),
       method: :delete,
       class: 'button',
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
