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
      etablissement_params, other_etablissements =
        if siret.length == 6 || siret.length == 9
          APIEntreprise::PfEtablissementAdapter.new(siret, procedure_id).to_params
        else
          APIEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
        end
      return nil if etablissement_params.blank?

      if siret.length > 9
        entreprise_params = APIEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params
        etablissement_params.merge!(entreprise_params) if entreprise_params.any?
      elsif other_etablissements && other_etablissements.size > 1
        return [dossier_or_champ.build_etablissement(etablissement_params), other_etablissements]
      end

      etablissement = dossier_or_champ.build_etablissement(etablissement_params)
      etablissement.save!
      if siret.length > 9
        perform_later_fetch_jobs(etablissement, procedure_id, user_id)
      end
      [etablissement, other_etablissements]
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
      etablissement_params, _other_etablissements = if siret.length == 6 || siret.length == 9
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

    # See: https://entreprise.api.gouv.fr/developpeurs#surveillance-etat-fournisseurs
    def api_insee_up?
      APIEntreprise::PfAPI.api_up?
    end

    def fr_api_insee_up?
      api_up?("https://entreprise.api.gouv.fr/ping/insee/sirene")
    end

    def api_djepva_up?
      api_up?("https://entreprise.api.gouv.fr/ping/djepva/api-association")
    end

    private

    def api_up?(url)
      response = Typhoeus.get(url, timeout: 1)
      if response.success?
        JSON.parse(response.body).fetch('status') == 'ok'
      else
        false
      end
    rescue => e
      Sentry.capture_exception(e)
      false
    end
  end
end
