class DossierService

  def initialize dossier, siret, france_connect_information
    @dossier = dossier
    @siret = siret
    @france_connect_information = france_connect_information
  end

  def dossier_informations!
    @entreprise_adapter = SIADE::EntrepriseAdapter.new(DossierService.siren @siret)

    if @entreprise_adapter.to_params.nil?
      raise RestClient::ResourceNotFound
    end

    @etablissement_adapter = SIADE::EtablissementAdapter.new(@siret)

    if @etablissement_adapter.to_params.nil?
      raise RestClient::ResourceNotFound
    end

    @dossier.create_entreprise(@entreprise_adapter.to_params)
    @dossier.create_etablissement(@etablissement_adapter.to_params)

    @rna_adapter = SIADE::RNAAdapter.new(@siret)
    @dossier.entreprise.create_rna_information(@rna_adapter.to_params)

    @exercices_adapter = SIADE::ExercicesAdapter.new(@siret)
    @dossier.etablissement.exercices.create(@exercices_adapter.to_params)

    @dossier.update_attributes(mandataire_social: mandataire_social?(@entreprise_adapter.mandataires_sociaux))
    @dossier.etablissement.update_attributes(entreprise: @dossier.entreprise)

    @dossier
  end


  def self.siren siret
    siret[0..8]
  end

  private

  def mandataire_social? mandataires_list
    unless @france_connect_information.nil?

      mandataires_list.each do |mandataire|
        return true if mandataire[:nom].upcase == @france_connect_information.family_name.upcase &&
            mandataire[:prenom].upcase == @france_connect_information.given_name.upcase &&
            mandataire[:date_naissance_timestamp] == @france_connect_information.birthdate.to_time.to_i
      end
    end

    false
  end
end
