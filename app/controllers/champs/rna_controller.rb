# frozen_string_literal: true

class Champs::RNAController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    rna = champs_attributes.values.first[:value]

    if !@champ.fetch_association!(rna) && @champ.association_fetch_error_key != :blank
      err = ActiveModel::Error.new(@champ, :value, @champ.association_fetch_error_key)
      @champ.errors.import(err)
    end
    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end
end
