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
      @error = "SIRET invalide"
    else
      etablissement_attributes = SIRETService.fetch(siret, @champ.dossier.procedure_id)
      if etablissement_attributes.present?
        @etablissement = @champ.build_etablissement(etablissement_attributes)
        @etablissement.champ = @champ
      else
        @error = "SIRET invalide"
      end
    end
    respond_to do |format|
      format.js
    end
  end
end
