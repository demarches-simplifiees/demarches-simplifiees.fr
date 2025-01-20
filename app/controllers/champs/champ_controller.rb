# frozen_string_literal: true

class Champs::ChampController < ApplicationController
  before_action :authenticate_logged_user!
  before_action :set_champ

  private

  def find_champ
    dossier = policy_scope(Dossier).includes(:champs, revision: [:types_de_champ]).find(params[:dossier_id])
    dossier.with_update_stream(current_user)
    type_de_champ = dossier.find_type_de_champ_by_stable_id(params[:stable_id])
    if type_de_champ.repetition?
      dossier.project_champ(type_de_champ)
    else
      dossier.champ_for_update(type_de_champ, row_id: params_row_id, updated_by: current_user.email)
    end
  end

  def params_row_id
    params[:row_id]
  end

  def set_champ
    @champ = find_champ
  end

  def propagate_touch_champs_changed
    @champ.touch
    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end
end
