# frozen_string_literal: true

class Champs::SiretController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    siret = champs_attributes.values.first[:value]

    if @champ.fetch_etablissement!(siret, current_user)
      @siret = @champ.etablissement.siret
    else
      @siret = @champ.etablissement_fetch_error_key
    end
  end
end
