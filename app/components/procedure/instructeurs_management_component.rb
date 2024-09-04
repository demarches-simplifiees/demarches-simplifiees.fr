# frozen_string_literal: true

class Procedure::InstructeursManagementComponent < ApplicationComponent
  def initialize(procedure:, groupe_instructeur:, instructeurs:, available_instructeur_emails:, disabled_as_super_admin:)
    @procedure = procedure
    @groupe_instructeur = groupe_instructeur
    @instructeurs = instructeurs
    @available_instructeur_emails = available_instructeur_emails
    @disabled_as_super_admin = disabled_as_super_admin
  end
end
