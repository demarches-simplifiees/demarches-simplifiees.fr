# frozen_string_literal: true

class Dossiers::AnnuaireEntrepriseLinkComponent < ApplicationComponent
  attr_reader :siret

  def initialize(siret:)
    @siret = siret
  end

  def call
    link_to "➡ Autres informations sur l’organisme sur « annuaire-entreprises.data.gouv.fr »",
      helpers.annuaire_link(siret),
      **helpers.external_link_attributes
  end
end
