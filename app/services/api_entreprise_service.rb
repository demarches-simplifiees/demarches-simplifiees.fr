class APIEntrepriseService
  class << self
    # create etablissement with EtablissementAdapter
    # enqueue api_entreprise jobs to retrieve
    # all informations we can get about a SIRET.
    #
    # Returns nil if the SIRET is unknown
    #
    # Raises a APIEntreprise::API::Error::RequestFailed exception on transient errors
    # (timeout, 5XX HTTP error code, etc.)
    #
    def create_etablissement(dossier_or_champ, siret, user_id = nil)
      procedure_id = dossier_or_champ.procedure.id

      etablissement_params = APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
      return nil if etablissement_params.empty?

      etablissement = dossier_or_champ.build_etablissement(etablissement_params)
      etablissement.save!

      perform_later_fetch_jobs(etablissement, procedure_id, user_id)

      etablissement
    end

    def create_etablissement_as_degraded_mode(dossier_or_champ, siret, user_id = nil)
      etablissement = dossier_or_champ.build_etablissement(siret: siret)
      etablissement.save!

      procedure_id = dossier_or_champ.procedure.id

      perform_later_fetch_jobs(etablissement, procedure_id, user_id, wait: 30.minutes)

      etablissement
    end

    def update_etablissement_from_degraded_mode(etablissement)
      procedure_id = etablissement.dossier.procedure.id
      siret = etablissement.siret
      etablissement_params = APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
      return nil if etablissement_params.empty?

      etablissement.update!(etablissement_params)
    end

    def perform_later_fetch_jobs(etablissement, procedure_id, user_id, wait: nil)
      [
        APIEntreprise::EntrepriseJob, APIEntreprise::AssociationJob, APIEntreprise::ExercicesJob,
        APIEntreprise::EffectifsJob, APIEntreprise::EffectifsAnnuelsJob, APIEntreprise::AttestationSocialeJob,
        APIEntreprise::BilansBdfJob
      ].each do |job|
        job.set(wait:).perform_later(etablissement.id, procedure_id)
      end

      APIEntreprise::AttestationFiscaleJob.set(wait:).perform_later(etablissement.id, procedure_id, user_id)
    end

    def api_up?(uname = "apie_2_etablissements")
      statuses = APIEntreprise::API.new.current_status.fetch(:results)

      # find results having uname = apie_2_etablissements
      status = statuses.find { |result| result[:uname] == uname }

      status.fetch(:code) == 200
    rescue => e
      Sentry.capture_exception(e, extra: { uname: uname })

      nil
    end
  end
end
