class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def add
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    @champs = @champ.add_row(@champ.dossier.revision)
  end

  def remove
    champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    champ.champs.where(row_id: params[:row_id]).destroy_all
    @row_id = params[:row_id]
  end
end
