class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def add
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    row = @champ.add_row(@champ.dossier.revision)
    @first_champ_id = row.map(&:focusable_input_id).compact.first
    @row_id = row.first&.row_id
  end

  def remove
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    @champ.champs.where(row_id: params[:row_id]).destroy_all
    @champ.reload
    @row_id = params[:row_id]
  end
end
