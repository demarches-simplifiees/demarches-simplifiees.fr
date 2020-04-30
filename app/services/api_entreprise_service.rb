class ApiEntrepriseService
  # Retrieve all informations we can get about a SIRET.
  #
  # Returns nil if the SIRET is unknown; and nested params
  # suitable for being saved into a Etablissement object otherwise.
  #
  # Raises a ApiEntreprise::API::RequestFailed exception on transcient errors
  # (timeout, 5XX HTTP error code, etc.)
  def self.get_etablissement_params_for_siret(siret, procedure_id, user_id = nil)
    etablissement_params = ApiEntreprise::EtablissementAdapter.new(siret, procedure_id).to_params
    entreprise_params = ApiEntreprise::EntrepriseAdapter.new(siret, procedure_id).to_params

    if etablissement_params.present? && entreprise_params.present?
      begin
        association_params = ApiEntreprise::RNAAdapter.new(siret, procedure_id).to_params
        etablissement_params.merge!(association_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        exercices_params = ApiEntreprise::ExercicesAdapter.new(siret, procedure_id).to_params
        etablissement_params.merge!(exercices_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        effectifs_params = ApiEntreprise::EffectifsAdapter.new(entreprise_params[:entreprise_siren], procedure_id, *get_current_valid_month_for_effectif).to_params
        etablissement_params.merge!(effectifs_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        effectifs_annuels_params = ApiEntreprise::EffectifsAnnuelsAdapter.new(entreprise_params[:entreprise_siren], procedure_id).to_params
        etablissement_params.merge!(effectifs_annuels_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        attestation_sociale_params = ApiEntreprise::AttestationSocialeAdapter.new(entreprise_params[:entreprise_siren], procedure_id).to_params
        etablissement_params.merge!(attestation_sociale_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        attestation_fiscale_params = ApiEntreprise::AttestationFiscaleAdapter.new(entreprise_params[:entreprise_siren], procedure_id, user_id).to_params
        etablissement_params.merge!(attestation_fiscale_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      begin
        bilans_bdf_params = ApiEntreprise::BilansBdfAdapter.new(entreprise_params[:entreprise_siren], procedure_id).to_params
        etablissement_params.merge!(bilans_bdf_params)
      rescue ApiEntreprise::API::RequestFailed
      end

      etablissement_params.merge(entreprise_params)
    end
  end

  private

  def self.get_current_valid_month_for_effectif
    today = Date.today
    date_update = Date.new(today.year, today.month, 15)

    if today >= date_update
      [today.strftime("%Y"), today.strftime("%m")]
    else
      date = today - 1.month
      [date.strftime("%Y"), date.strftime("%m")]
    end
  end
end
