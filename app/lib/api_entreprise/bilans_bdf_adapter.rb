class ApiEntreprise::BilansBdfAdapter < ApiEntreprise::Adapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  private

  def get_resource
    ApiEntreprise::API.bilans_bdf(siren, @procedure_id)
  end

  def process_params
    if data_source[:bilans].present?
      {
        entreprise_bilans_bdf: data_source[:bilans],
        entreprise_bilans_bdf_monnaie: data_source[:monnaie]
      }
    else
      {}
    end
  end
end
