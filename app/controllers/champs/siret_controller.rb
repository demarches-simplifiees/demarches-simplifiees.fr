# frozen_string_literal: true

class Champs::SiretController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    siret = champs_attributes.values.first[:value]

    @siret = if @champ.fetch_etablissement!(siret, current_user)
      @champ.etablissement.siret
    else
      @champ.etablissement_fetch_error_key
    end

    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end
end
