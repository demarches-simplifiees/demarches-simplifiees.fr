# frozen_string_literal: true

# Component that displays an error message in a modal when an instructeur tries to access a dossier they don't have access to.
# It also displays a list of administrators for the procedure, if any.
class Dossiers::NoAccessToDossierComponent < ApplicationComponent
  # Component constructor
  # @param dossier [Dossier] the dossier that the instructeur access
  def initialize(dossier)
    @dossier = dossier
    procedure = @dossier.procedure
    @procedure_name = procedure.libelle
    @administrateurs_emails = procedure.administrateurs.map(&:email)
  end

  attr_reader :dossier
  attr_reader :procedure_name
  attr_reader :administrateurs_emails
end
