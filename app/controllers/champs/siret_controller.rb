class Champs::SiretController < ApplicationController
  def index
    siret, champ_id = params.required([:siret, :champ_id])
    @champ = Champs::SiretChamp.find(champ_id)
    @etablissement = @champ.etablissement
    if siret == 'blank'
      if @etablissement
        @etablissement.mark_for_destruction
      end
      @blank = true
    elsif siret == 'invalid'
      if @etablissement
        @etablissement.mark_for_destruction
      end
      @error = "Le numéro de SIRET doit comporter exactement 14 chiffres."
    else
      etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(siret, @champ.dossier.procedure_id)
      if etablissement_attributes.present?
        @etablissement = @champ.build_etablissement(etablissement_attributes)
        @etablissement.champ = @champ
      else
        message = ['Nous n’avons pas trouvé d’établissement correspondant à ce numéro de SIRET.']
        message << helpers.link_to('Plus d’informations', "https://faq.demarches-simplifiees.fr/article/4-erreur-siret", target: '_blank')
        @error = helpers.safe_join(message, ' ')
      end
    end
    respond_to do |format|
      format.js
    end
  end
end
