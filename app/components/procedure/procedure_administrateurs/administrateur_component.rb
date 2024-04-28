# frozen_string_literal: true

class Procedure::ProcedureAdministrateurs::AdministrateurComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(procedure:, administrateur:)
    @procedure = procedure
    @administrateur = administrateur
  end

  def email
    if @administrateur == current_administrateur
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
       admin_procedure_administrateur_path(@procedure, @administrateur),
       method: :delete,
       class: 'fr-btn fr-btn--tertiary fr-btn--sm',
       form: { data: { turbo: true, turbo_confirm: "Retirer « #{@administrateur.email} » des administrateurs de « #{@procedure.libelle} » ?" } }
    end
  end

  def is_there_at_least_another_active_admin?
    if @administrateur.active?
      @procedure.administrateurs.count(&:active?) > 1
    else
      @procedure.administrateurs.count(&:active?) >= 1
    end
  end
end
