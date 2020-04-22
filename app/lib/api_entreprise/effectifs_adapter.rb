class ApiEntreprise::EffectifsAdapter < ApiEntreprise::Adapter
  def initialize(siren, procedure_id, annee, mois)
    @siren = siren
    @procedure_id = procedure_id
    @annee = annee
    @mois = mois
  end

  private

  def get_resource
    ApiEntreprise::API.effectifs(@siren, @procedure_id, @annee, @mois)
  end

  def process_params
    if data_source[:effectifs_mensuels].present?
      {
        entreprise_effectif_mensuel: data_source[:effectifs_mensuels],
        entreprise_effectif_mois: @mois,
        entreprise_effectif_annee: @annee
      }
    else
      {}
    end
  end
end
