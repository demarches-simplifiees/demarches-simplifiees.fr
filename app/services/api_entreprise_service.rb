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
    def create_etablissement(dossier_or_champ, siret, user_id = nil)
      procedure_id = dossier_or_champ.procedure.id
      etablissement_params =
        if siret.length == 6
          APIEntreprise::PfEtablissementAdapter.new(siret, procedure_id).to_params
        else
          APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
        end
      return nil if etablissement_params.empty?

      entreprise_params = APIEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params
      etablissement_params.merge!(entreprise_params) if entreprise_params.any?

      etablissement = dossier_or_champ.build_etablissement(etablissement_params)
      etablissement.save!
      if siret.length > 6
        perform_later_fetch_jobs(etablissement, procedure_id, user_id)
      end
      etablissement
    end

    def create_etablissement_as_degraded_mode(dossier_or_champ, siret, user_id = nil)
      etablissement = dossier_or_champ.build_etablissement(siret: siret)
      etablissement.save!

      procedure_id = dossier_or_champ.procedure.id

      perform_later_fetch_jobs(etablissement, procedure_id, user_id, wait: 30.minutes)

      etablissement
    end

    def update_etablissement_from_degraded_mode(etablissement, procedure_id)
      siret = etablissement.siret
      etablissement_params = if siret.length == 6
        APIEntreprise::PfEtablissementAdapter.new(siret, procedure_id).to_params
      else
        APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
      end
      return nil if etablissement_params.empty?

      etablissement.update!(etablissement_params)
    end

    def perform_later_fetch_jobs(etablissement, procedure_id, user_id, wait: nil)
      [
        APIEntreprise::EntrepriseJob, APIEntreprise::ExtraitKbisJob, APIEntreprise::TvaJob,
        APIEntreprise::AssociationJob, APIEntreprise::ExercicesJob,
        APIEntreprise::EffectifsJob, APIEntreprise::EffectifsAnnuelsJob, APIEntreprise::AttestationSocialeJob,
        APIEntreprise::BilansBdfJob
      ].each do |job|
        job.set(wait:).perform_later(etablissement.id, procedure_id)
      end

      APIEntreprise::AttestationFiscaleJob.set(wait:).perform_later(etablissement.id, procedure_id, user_id)
    end

    def fr_api_up?
      APIEntreprise::API.new.current_status.fetch(:page).fetch(:status) == 'UP'
    rescue => e
      Sentry.capture_exception(e)
      false
    end

    def api_up?(uname = "apie_2_etablissements")
      APIEntreprise::PfAPI.api_up?
    end
  end
end
