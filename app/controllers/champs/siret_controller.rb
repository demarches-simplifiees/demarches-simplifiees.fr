# frozen_string_literal: true

class Champs::SiretController < Champs::ChampController
  def show
    champs_attributes = params.dig(:dossier, :champs_public_attributes) || params.dig(:dossier, :champs_private_attributes)
    siret = champs_attributes.values.first[:value]

    @champ.fetch_etablissement!(siret, current_user)

    # Except of prefill first load, validation is made on update with validate_champ_value
    # Anyway it would be clear when updating the value without validation
    @champ.validate(params[:validate].to_sym) if params[:validate]

    @champ.update_timestamps
  end
end
