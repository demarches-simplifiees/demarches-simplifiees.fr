class ApiEntreprise::EffectifsAnnuelsAdapter < ApiEntreprise::Adapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  private

  def get_resource
    ApiEntreprise::API.effectifs_annuels(siren, @procedure_id)
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
