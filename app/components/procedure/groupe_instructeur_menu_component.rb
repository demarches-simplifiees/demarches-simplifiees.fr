# frozen_string_literal: true

class Procedure::GroupeInstructeurMenuComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def links
    links = [
      { name: 'Paramètres du groupe', url: '#parametres-groupe' },
      { name: 'Dossiers affectés', url: '#dossiers-affectes' },
      { name: 'Règle(s) de routage', url: '#regles-routage' },
      { name: 'Affectation des instructeurs', url: '#affectation-instructeurs' },
      { name: 'Informations de contact', url: '#informations-contact' }
    ]
    links.push({ name: 'Tampon de l’attestation', url: '#tampon-attestation' }) if @procedure.attestation_acceptation_template&.activated? || @procedure.attestation_refus_template&.activated?
    links
  end
end
