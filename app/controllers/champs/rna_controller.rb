# frozen_string_literal: true

class Champs::RNAController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    rna = champs_attributes.values.first[:value]

    unless @champ.fetch_association!(rna)
      @error = @champ.association_fetch_error_key
    end
  end
end
