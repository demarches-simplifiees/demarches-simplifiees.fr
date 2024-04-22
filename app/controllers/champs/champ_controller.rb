class Champs::ChampController < ApplicationController
  before_action :authenticate_logged_user!
  before_action :set_champ

  private

  def find_champ
    if params[:champ_id].present?
      policy_scope(Champ)
        .includes(:type_de_champ, dossier: :champs)
        .find(params[:champ_id])
    else
      dossier = policy_scope(Dossier).includes(:champs, revision: [:types_de_champ]).find(params[:dossier_id])
      type_de_champ = dossier.find_type_de_champ_by_stable_id(params[:stable_id])
      dossier.champ_for_update(type_de_champ, params_row_id)
    end
  end

  def params_row_id
    params[:row_id]
  end

  def set_champ
    @champ = find_champ
  end
end
