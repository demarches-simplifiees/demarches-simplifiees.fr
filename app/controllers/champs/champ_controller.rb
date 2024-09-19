# frozen_string_literal: true

class Champs::ChampController < ApplicationController
  before_action :authenticate_logged_user!
  before_action :set_champ

  private

  def find_champ
    dossier = policy_scope(Dossier).includes(:champs, revision: [:types_de_champ]).find(params[:dossier_id])
    type_de_champ = dossier.find_type_de_champ_by_stable_id(params[:stable_id])
    dossier.champ_for_update(type_de_champ, params_row_id, updated_by: current_user.email)
  end

  def params_row_id
    params[:row_id]
  end

  def set_champ
    @champ = find_champ
  end
end
