class APIEntreprise::EffectifsAdapter < APIEntreprise::Adapter
  def initialize(siret, procedure_id, annee, mois)
    @siret = siret
    @procedure_id = procedure_id
    @annee = annee
    @mois = mois
  end

  private

  def get_resource
    api(@procedure_id).effectifs(siren, @annee, @mois)
  end

  def process_params
    if data_source[:effectifs_mensuels].present?
      {
        entreprise_effectif_mensuel: data_source[:effectifs_mensuels],
        entreprise_effectif_mois: data_source[:mois],
        entreprise_effectif_annee: data_source[:annee]
      }
    else
      {}
    end
  end
end
