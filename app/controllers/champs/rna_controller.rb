# frozen_string_literal: true

class Champs::RNAController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    rna = champs_attributes.values.first[:value]

    @champ.fetch_association!(rna)
    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end
end
