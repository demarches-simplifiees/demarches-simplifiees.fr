class APIParticulier::DossierJob < APIParticulier::Job
  def perform(dossier_id)
    dossier = Dossier.includes(:procedure).find(dossier_id)
    donnees_sources = APIParticulier::Services::FetchData.new(dossier).call
    masque_de_procedure = dossier.procedure.api_particulier_sources
    donnees_assainies = APIParticulier::Services::SanitizeData.new.call(donnees_sources, masque_de_procedure)

    Dossier.transaction do
      dossier.individual.update!(api_particulier_donnees: donnees_assainies)
      dossier.update_column(:api_particulier_job_exceptions, nil)
    end
  end
end
