# frozen_string_literal: true

class APIEntreprise::EtablissementJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    APIEntrepriseService.update_etablissement_from_degraded_mode(etablissement, procedure_id)
  end
end
