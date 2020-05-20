class ApiEntrepriseService
  # create etablissement with EtablissementAdapter
  # enqueue api_entreprise jobs to retrieve
  # all informations we can get about a SIRET.
  #
  # Returns nil if the SIRET is unknown
  #
  # Raises a ApiEntreprise::API::RequestFailed exception on transient errors
  # (timeout, 5XX HTTP error code, etc.)
  def self.create_etablissement(dossier, siret, user_id = nil)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, dossier.procedure.id).to_params
    return nil if etablissement_params.empty?

    etablissement = dossier.build_etablissement(etablissement_params)
    etablissement.save

    [
      ApiEntreprise::EntrepriseJob, ApiEntreprise::AssociationJob, ApiEntreprise::ExercicesJob,
      ApiEntreprise::EffectifsJob, ApiEntreprise::EffectifsAnnuelsJob, ApiEntreprise::AttestationSocialeJob,
      ApiEntreprise::BilansBdfJob
    ].each do |job|
      job.perform_later(etablissement.id, dossier.procedure.id)
    end
    ApiEntreprise::AttestationFiscaleJob.perform_later(etablissement.id, dossier.procedure.id, user_id)

    etablissement
  end
end
