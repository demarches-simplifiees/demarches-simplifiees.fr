# frozen_string_literal: true

class APIEntreprise::AssociationJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    Sentry.set_tags(siret: etablissement.siret)
    with_adapter(APIEntreprise::RNAAdapter.new(etablissement.siret.first(9), procedure_id)) do |params|
      # Adresse is already populated from SIRENE as an inlined adresse, not a hash.
      etablissement.update!(params.except("adresse"))
    end
  end
end
