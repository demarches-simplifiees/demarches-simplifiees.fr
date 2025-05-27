# frozen_string_literal: true

class Dossiers::NoAccessToDossierComponent < ViewComponent::Base
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
