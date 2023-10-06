class GroupeGestionnaire::GroupeGestionnaireAdministrateurs::AdministrateurComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, administrateur:)
    @groupe_gestionnaire = groupe_gestionnaire
    @administrateur = administrateur
  end

  def email
    if @administrateur == current_gestionnaire
      "#{@administrateur.email} (C’est vous !)"
    else
      @administrateur.email
    end
  end

  def created_at
    try_format_datetime(@administrateur.created_at)
  end

  def registration_state
    @administrateur.registration_state
  end

  def remove_button
    if is_there_at_least_another_active_admin?
      button_to 'Retirer',
       gestionnaire_groupe_gestionnaire_administrateur_path(@groupe_gestionnaire, @administrateur),
       method: :delete,
       class: 'button',
       form: { data: { turbo: true, turbo_confirm: "Retirer « #{@administrateur.email} » des administrateurs de « #{@groupe_gestionnaire.name} » ?" } }
    end
  end

  def is_there_at_least_another_active_admin?
    if @administrateur.active?
      @groupe_gestionnaire.administrateurs.count(&:active?) > 1
    else
      @groupe_gestionnaire.administrateurs.count(&:active?) >= 1
    end
  end
end
