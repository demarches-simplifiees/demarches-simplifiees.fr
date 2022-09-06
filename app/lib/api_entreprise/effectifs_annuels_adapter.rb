class APIEntreprise::EffectifsAnnuelsAdapter < APIEntreprise::Adapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  private

  def get_resource
    api(@procedure_id).effectifs_annuels(siren)
  end

  def process_params
    if data_source[:effectifs_annuels].present?
      {
        entreprise_effectif_annuel: data_source[:effectifs_annuels],
        entreprise_effectif_annuel_annee: data_source[:annee]
      }
    else
      {}
    end
  end
end
