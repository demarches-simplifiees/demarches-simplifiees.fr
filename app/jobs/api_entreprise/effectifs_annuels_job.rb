# frozen_string_literal: true

class APIEntreprise::EffectifsAnnuelsJob < APIEntreprise::Job
  def perform(etablissement_id, procedure_id, year = default_year)
    find_etablissement(etablissement_id)
    etablissement_params = APIEntreprise::EffectifsAnnuelsAdapter.new(etablissement.siret, procedure_id, year).to_params
    etablissement.update!(etablissement_params)
  end

  private

  def default_year
    Date.current.year - 1
  end
end
